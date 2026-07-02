import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';


import '../core/utils/safe_change_notifier.dart';
import '../models/firestore_models.dart';
import '../repositories/cart_repository.dart';
import '../repositories/voucher_repository.dart';

class CartProvider extends SafeChangeNotifier {
  CartProvider({
    CartRepository? repository,
    VoucherRepository? voucherRepository,
    List<CartItemModel> initialItems = const [],
    this.deliveryFee = 2000,
  }) : _repository = repository,
       _voucherRepository = voucherRepository,
       _items = List<CartItemModel>.of(initialItems);

  CartRepository? _repository;
  VoucherRepository? _voucherRepository;
  StreamSubscription<CartModel?>? _subscription;
  List<CartItemModel> _items;
  String? _userId;
  VoucherModel? _selectedVoucher;
  String? _voucherId;
  String? _voucherCode;
  int _storedVoucherDiscount = 0;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  final int deliveryFee;

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  String? get voucherCode => _selectedVoucher?.code ?? _voucherCode;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  int get voucherDiscount =>
      (_selectedVoucher == null
              ? _storedVoucherDiscount
              : _discount(_selectedVoucher!))
          .clamp(0, subtotal + deliveryFee)
          .toInt();
  int get total => _items.isEmpty
      ? 0
      : (subtotal + deliveryFee - voucherDiscount).clamp(0, 1 << 31).toInt();
  bool get hasItems => _items.isNotEmpty;

  Future<void> bindCurrentUser() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_userId == user.uid && _subscription != null) return;
    _userId = user.uid;
    _loading = true;
    notifyListeners();
    await _subscription?.cancel();
    _repository ??= CartRepository();
    _subscription = _repository!
        .watchCart(user.uid)
        .listen(
          (cart) async {
            _items = cart?.items ?? const [];
            _voucherId = cart?.voucherId;
            _voucherCode = cart?.voucherCode;
            _storedVoucherDiscount = cart?.voucherDiscount ?? 0;
            final voucherId = _voucherId;
            if (_selectedVoucher?.id != voucherId) {
              _selectedVoucher = null;
              if (voucherId != null) {
                VoucherModel? restored;
                try {
                  _voucherRepository ??= VoucherRepository();
                  final userVoucher = await _voucherRepository!.getUserVoucherById(voucherId);
                  if (userVoucher != null) {
                    final baseVoucher = await _voucherRepository!.getById(userVoucher.voucherId);
                    if (baseVoucher != null) {
                      final isUsed = userVoucher.status == 'used';
                      final isExpired = userVoucher.status == 'expired' || userVoucher.expiredAt.isBefore(DateTime.now());
                      final isActive = (userVoucher.status == 'active' || userVoucher.status == 'available') && !isExpired;
                      restored = VoucherModel(
                        id: userVoucher.id,
                        title: baseVoucher.title,
                        code: baseVoucher.code,
                        description: baseVoucher.description,
                        discountType: baseVoucher.discountType,
                        discountValue: baseVoucher.discountValue,
                        minOrderAmount: baseVoucher.minOrderAmount,
                        maxDiscount: baseVoucher.maxDiscount,
                        usageLimit: baseVoucher.usageLimit,
                        usedCount: isUsed ? 1 : 0,
                        claimLimit: baseVoucher.claimLimit,
                        claimedCount: baseVoucher.claimedCount,
                        userLimit: baseVoucher.userLimit,
                        exchangePoints: baseVoucher.exchangePoints,
                        isExchangeable: baseVoucher.isExchangeable,
                        isClaimable: baseVoucher.isClaimable,
                        isActive: isActive,
                        expiredAt: userVoucher.expiredAt,
                      );
                    }
                  }
                } on Object catch (error) {
                  if (_disposed) return;
                  _error = error.toString();
                }
                if (_disposed || voucherId != _voucherId) return;
                if (restored != null && canApply(restored)) {
                  _selectedVoucher = restored;
                  _storedVoucherDiscount = _discount(restored);
                } else if (_error == null) {
                  _voucherId = null;
                  _voucherCode = null;
                  _storedVoucherDiscount = 0;
                  unawaited(_sync());
                }
              }
            }
            _loading = false;
            if (_selectedVoucher != null || voucherId == null) {
              _error = null;
            }
            if (!_disposed) notifyListeners();
          },
          onError: (Object error) {
            _loading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> addItem(CartItemModel item) async {
    final normalized = item.copyWith(
      itemTotal: (item.basePrice + item.toppingTotal) * item.quantity,
    );
    final index = _items.indexWhere((value) => value.uniqueKey == normalized.uniqueKey);
    if (index == -1) {
      _items = [..._items, normalized];
    } else {
      final updated = _items[index].copyWith(
        quantity: _items[index].quantity + normalized.quantity,
        itemTotal:
            (_items[index].basePrice + _items[index].toppingTotal) *
            (_items[index].quantity + normalized.quantity),
      );
      _items = [..._items]..[index] = updated;
    }
    _revalidateVoucher();
    notifyListeners();
    await _sync();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    _items = [..._items]..removeAt(index);
    _revalidateVoucher();
    notifyListeners();
    await _sync();
  }

  Future<void> increaseAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    _items = [..._items]
      ..[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
        itemTotal:
            (_items[index].basePrice + _items[index].toppingTotal) *
            (_items[index].quantity + 1),
      );
    _revalidateVoucher();
    notifyListeners();
    await _sync();
  }

  Future<void> decreaseAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity <= 1) {
      await removeAt(index);
      return;
    }
    _items = [..._items]
      ..[index] = _items[index].copyWith(
        quantity: _items[index].quantity - 1,
        itemTotal:
            (_items[index].basePrice + _items[index].toppingTotal) *
            (_items[index].quantity - 1),
      );
    _revalidateVoucher();
    notifyListeners();
    await _sync();
  }

  Future<void> clear() async {
    _items = const [];
    removeVoucher(sync: false);
    notifyListeners();
    final userId = _userId;
    if (userId != null) {
      try {
        await (_repository ??= CartRepository()).clear(userId);
      } catch (error) {
        _error = error.toString();
        notifyListeners();
      }
    }
  }

  bool canApply(VoucherModel voucher) =>
      voucher.isActive &&
      voucher.expiredAt.isAfter(DateTime.now()) &&
      subtotal >= voucher.minOrderAmount;

  Future<bool> applyVoucher(VoucherModel voucher) async {
    if (!canApply(voucher)) return false;
    _selectedVoucher = voucher;
    _voucherId = voucher.id;
    _voucherCode = voucher.code;
    _storedVoucherDiscount = _discount(voucher);
    notifyListeners();
    await _sync();
    return true;
  }

  void removeVoucher({bool sync = true}) {
    _selectedVoucher = null;
    _voucherId = null;
    _voucherCode = null;
    _storedVoucherDiscount = 0;
    notifyListeners();
    if (sync) unawaited(_sync());
  }

  int _discount(VoucherModel voucher) {
    var amount = switch (voucher.discountType.toLowerCase()) {
      'percent' => subtotal * voucher.discountValue ~/ 100,
      'shipping' || 'freeship' || 'free_shipping' => deliveryFee,
      _ => voucher.discountValue,
    };
    if (voucher.discountType.toLowerCase() == 'percent' && voucher.maxDiscount > 0) {
      if (amount > voucher.maxDiscount) {
        amount = voucher.maxDiscount;
      }
    }
    return amount.clamp(0, subtotal + deliveryFee).toInt();
  }

  void _revalidateVoucher() {
    final voucher = _selectedVoucher;
    if (voucher == null && _voucherId != null) return;
    if (voucher != null && !canApply(voucher)) {
      _selectedVoucher = null;
      _voucherId = null;
      _voucherCode = null;
      _storedVoucherDiscount = 0;
    } else if (voucher != null) {
      _storedVoucherDiscount = _discount(voucher);
    }
  }

  Future<void> _sync() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await (_repository ??= CartRepository()).saveCart(
        CartModel(
          userId: userId,
          items: _items,
          updatedAt: DateTime.now(),
          voucherId: _voucherId,
          voucherCode: _voucherCode,
          voucherDiscount: voucherDiscount,
          deliveryFee: deliveryFee,
        ),
      );
      _error = null;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/firestore_models.dart' as store;
import '../repositories/voucher_repository.dart';

class VoucherProvider extends ChangeNotifier {
  VoucherProvider({VoucherRepository? repository}) : _repository = repository;

  VoucherRepository? _repository;
  StreamSubscription<List<store.UserVoucherModel>>? _subscription;
  List<store.VoucherModel> _vouchers = const [];
  bool _loading = false;
  String? _error;

  List<store.VoucherModel> get vouchers => List.unmodifiable(_vouchers);
  bool get loading => _loading;
  String? get error => _error;

  void bind() {
    if (Firebase.apps.isEmpty || _subscription != null) return;
    _loading = true;
    notifyListeners();
    _repository ??= VoucherRepository();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _loading = false;
      _vouchers = const [];
      notifyListeners();
      return;
    }

    _subscription = _repository!.watchUserVouchers(user.uid).listen(
      (items) {
        _vouchers = items.map((uv) => store.VoucherModel(
          id: uv.id, // UserVoucher ID
          title: uv.title,
          code: uv.voucherCode,
          description: uv.description,
          discountType: uv.discountType,
          discountValue: uv.discountValue,
          minOrderAmount: uv.minOrderAmount,
          maxDiscount: uv.maxDiscount,
          usageLimit: 1,
          usedCount: uv.status == 'used' ? 1 : 0,
          claimLimit: 1,
          claimedCount: 1,
          userLimit: 1,
          exchangePoints: 0,
          isExchangeable: false,
          isClaimable: false,
          isActive: uv.status == 'available',
          expiredAt: uv.expiredAt,
        )).toList();
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _loading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  List<store.VoucherModel> validFor(int subtotal) {
    final now = DateTime.now();
    return _vouchers
        .where(
          (voucher) =>
              voucher.isActive &&
              voucher.expiredAt.isAfter(now) &&
              subtotal >= voucher.minOrderAmount,
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/firestore_models.dart' as store;
import '../repositories/voucher_repository.dart';

class VoucherProvider extends ChangeNotifier {
  VoucherProvider({VoucherRepository? repository}) : _repository = repository;

  VoucherRepository? _repository;
  StreamSubscription<List<store.UserVoucherModel>>? _userSub;
  StreamSubscription<List<store.VoucherModel>>? _vouchersSub;
  List<store.UserVoucherModel> _rawUserVouchers = const [];
  List<store.VoucherModel> _rawVouchers = const [];
  List<store.VoucherModel> _vouchers = const [];
  bool _loading = false;
  String? _error;

  List<store.VoucherModel> get vouchers => List.unmodifiable(_vouchers);
  bool get loading => _loading;
  String? get error => _error;

  void bind() {
    if (Firebase.apps.isEmpty || _userSub != null) return;
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

    _vouchersSub = _repository!.watchVouchers().listen(
      (vouchers) {
        _rawVouchers = vouchers;
        _combine();
      },
      onError: (Object error) {
        _loading = false;
        _error = error.toString();
        notifyListeners();
      },
    );

    _userSub = _repository!.watchUserVouchers(user.uid).listen(
      (items) {
        _rawUserVouchers = items;
        _combine();
      },
      onError: (Object error) {
        _loading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void _combine() {
    final combined = <store.VoucherModel>[];
    for (final uv in _rawUserVouchers) {
      store.VoucherModel? voucher;
      final voucherId = uv.voucherId.trim();
      if (voucherId.isNotEmpty) {
        for (final v in _rawVouchers) {
          if (v.id == voucherId) {
            voucher = v;
            break;
          }
        }
      }
      
      if (voucher == null) {
        final code = uv.voucherCode.trim();
        if (code.isNotEmpty) {
          for (final v in _rawVouchers) {
            if (v.code == code) {
              voucher = v;
              break;
            }
          }
        }
      }

      if (voucher == null) continue;

      final isUsed = uv.status == 'used';
      final isExpired = uv.status == 'expired' || uv.expiredAt.isBefore(DateTime.now());
      final isActive = (uv.status == 'active' || uv.status == 'available') && !isExpired;

      combined.add(store.VoucherModel(
        id: uv.id, // UserVoucher document ID
        title: voucher.title,
        code: voucher.code,
        description: voucher.description,
        discountType: voucher.discountType,
        discountValue: voucher.discountValue,
        minOrderAmount: voucher.minOrderAmount,
        maxDiscount: voucher.maxDiscount,
        usageLimit: voucher.usageLimit,
        usedCount: isUsed ? 1 : 0,
        claimLimit: voucher.claimLimit,
        claimedCount: voucher.claimedCount,
        userLimit: voucher.userLimit,
        exchangePoints: voucher.exchangePoints,
        isExchangeable: voucher.isExchangeable,
        isClaimable: voucher.isClaimable,
        isActive: isActive,
        expiredAt: uv.expiredAt,
      ));
    }
    _vouchers = combined;
    _loading = false;
    _error = null;
    notifyListeners();
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
    _vouchersSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}

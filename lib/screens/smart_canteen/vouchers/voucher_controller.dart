import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/voucher_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../reward_points/reward_model.dart';
import 'voucher_model.dart';

class VoucherController extends SafeChangeNotifier {
  VoucherController({this.receivedReward, VoucherRepository? repository})
    : _repository = repository,
      _filter = receivedReward != null
          ? VoucherFilter.mine
          : VoucherFilter.claimable;

  final RewardItemModel? receivedReward;
  VoucherRepository? _repository;
  List<VoucherModel> _vouchers = const [];
  List<VoucherHistoryModel> _history = const [];
  VoucherFilter _filter;
  String _query = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _hasError = false;
  bool _disposed = false;

  StreamSubscription<List<store.VoucherModel>>? _vouchersSubscription;
  StreamSubscription<List<store.UserVoucherModel>>? _userVouchersSubscription;
  List<store.VoucherModel> _rawVouchers = const [];
  List<store.UserVoucherModel> _rawUserVouchers = const [];

  VoucherFilter get filter => _filter;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get hasError => _hasError;
  List<VoucherHistoryModel> get history => _history;

  List<VoucherModel> get visibleVouchers {
    final query = _query.trim().toLowerCase();
    return _vouchers
        .where((voucher) {
          if (query.isEmpty) {
            return true;
          }
          final searchable =
              '${voucher.title} ${voucher.code} ${voucher.description}'
                  .toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  VoucherModel? get featuredVoucher {
    if (_vouchers.isEmpty) return null;
    return _vouchers.first;
  }

  int get totalCount => _vouchers.length;
  int get expiringCount => _vouchers
      .where((item) => item.status == VoucherStatus.expiringSoon)
      .length;
  int get usedCount =>
      _vouchers.where((item) => item.status == VoucherStatus.used).length;
  int get totalSaved =>
      _history.fold(0, (total, item) => total + item.savedAmount);

  void load() {
    if (Firebase.apps.isNotEmpty) {
      _repository ??= VoucherRepository();
      _loading = true;
      _hasError = false;
      _notify();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;

        unawaited(_repository!.checkAndExpireUserVouchers(uid));

        _vouchersSubscription?.cancel();
        _userVouchersSubscription?.cancel();
        unawaited(_loadRemoteVouchers(uid));
      } else {
        _vouchersSubscription?.cancel();
        _userVouchersSubscription?.cancel();
        unawaited(_loadRemoteVouchers(''));
      }
      return;
    }

    final List<VoucherModel> localList = [
      if (receivedReward case final reward?) _voucherFromReward(reward),
      ...demoVouchers,
    ];
    _vouchers = localList.where((v) {
      if (_filter == VoucherFilter.claimable) {
        return v.id == 'voucher_featured' || v.id == 'voucher_freeship';
      } else if (_filter == VoucherFilter.mine) {
        return v.status == VoucherStatus.available ||
            v.status == VoucherStatus.expiringSoon ||
            v.id == 'reward_received';
      } else if (_filter == VoucherFilter.used) {
        return v.status == VoucherStatus.used;
      } else if (_filter == VoucherFilter.expired) {
        return v.status == VoucherStatus.expired;
      }
      return true;
    }).toList();
    _history = List<VoucherHistoryModel>.of(demoVoucherHistory);
    _loading = false;
    _notify();
  }

  Future<void> _loadRemoteVouchers(String uid) async {
    try {
      _rawVouchers = await _repository!.loadVouchers(forceRefresh: _refreshing);
      _rawUserVouchers = uid.isEmpty
          ? const []
          : await _repository!.loadUserVouchers(uid, forceRefresh: _refreshing);
      _updateCombinedList(uid);
    } catch (_) {
      _loading = false;
      _refreshing = false;
      _hasError = true;
      _notify();
    }
  }

  void _updateCombinedList(String userId) {
    if (_disposed) return;
    final now = DateTime.now();
    final List<VoucherModel> combined = [];

    final claimedIds = _rawUserVouchers
        .map((uv) => uv.voucherId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final claimedCodes = _rawUserVouchers
        .map((uv) => uv.voucherCode)
        .where((code) => code.isNotEmpty)
        .toSet();

    if (_filter == VoucherFilter.claimable) {
      final claimableVouchers = _rawVouchers.where((v) {
        final isClaimed =
            claimedIds.contains(v.id) || claimedCodes.contains(v.code);
        final isExpired = v.expiredAt.isBefore(now);
        return v.isActive && !isClaimed && !isExpired;
      });
      combined.addAll(claimableVouchers.map(_fromFirestoreVoucher));
    } else if (_filter == VoucherFilter.mine) {
      final mineVouchers = _rawUserVouchers.where((uv) {
        final isExpired = uv.expiredAt.isBefore(now);
        return (uv.status == 'active' || uv.status == 'available') &&
            !isExpired;
      });
      combined.addAll(
        mineVouchers.map(_mergeUserVoucher).whereType<VoucherModel>(),
      );
    } else if (_filter == VoucherFilter.used) {
      final usedVouchers = _rawUserVouchers.where((uv) => uv.status == 'used');
      combined.addAll(
        usedVouchers.map(_mergeUserVoucher).whereType<VoucherModel>(),
      );
    } else if (_filter == VoucherFilter.expired) {
      final expiredVouchers = _rawUserVouchers.where((uv) {
        final isExpired = uv.expiredAt.isBefore(now);
        return uv.status == 'expired' ||
            ((uv.status == 'active' || uv.status == 'available') && isExpired);
      });
      combined.addAll(
        expiredVouchers.map(_mergeUserVoucher).whereType<VoucherModel>(),
      );
    }

    _vouchers = combined;
    _loading = false;
    _refreshing = false;
    _notify();
  }

  Future<void> claim(BuildContext context, String voucherId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để nhận voucher.')),
      );
      return;
    }
    try {
      final result = await _repository!.claimVoucher(user.uid, voucherId);
      if (!context.mounted) return;
      if (result.isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu mã ưu đãi')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Đã xảy ra lỗi khi nhận voucher.'),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Error claiming voucher in UI: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (Firebase.apps.isNotEmpty) {
      _refreshing = true;
      _notify();
      load();
      return;
    }
    _refreshing = false;
    _notify();
  }

  void updateSearch(String value) {
    if (_query == value) {
      return;
    }
    _query = value;
    _notify();
  }

  void clearSearch() => updateSearch('');

  void setFilter(VoucherFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    if (Firebase.apps.isEmpty) {
      load();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    _updateCombinedList(user?.uid ?? '');
  }

  int countFor(VoucherFilter filter) {
    if (Firebase.apps.isEmpty) {
      final List<VoucherModel> localList = [
        if (receivedReward case final reward?) _voucherFromReward(reward),
        ...demoVouchers,
      ];
      return localList.where((v) {
        if (filter == VoucherFilter.claimable) {
          return v.id == 'voucher_featured' || v.id == 'voucher_freeship';
        } else if (filter == VoucherFilter.mine) {
          return v.status == VoucherStatus.available ||
              v.status == VoucherStatus.expiringSoon ||
              v.id == 'reward_received';
        } else if (filter == VoucherFilter.used) {
          return v.status == VoucherStatus.used;
        } else if (filter == VoucherFilter.expired) {
          return v.status == VoucherStatus.expired;
        }
        return true;
      }).length;
    }
    final now = DateTime.now();
    final claimedIds = _rawUserVouchers
        .map((uv) => uv.voucherId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final claimedCodes = _rawUserVouchers
        .map((uv) => uv.voucherCode)
        .where((code) => code.isNotEmpty)
        .toSet();

    if (filter == VoucherFilter.claimable) {
      return _rawVouchers.where((v) {
        final isClaimed =
            claimedIds.contains(v.id) || claimedCodes.contains(v.code);
        final isExpired = v.expiredAt.isBefore(now);
        return v.isActive && !isClaimed && !isExpired;
      }).length;
    } else if (filter == VoucherFilter.mine) {
      return _rawUserVouchers.where((uv) {
        final isExpired = uv.expiredAt.isBefore(now);
        final hasValidVoucher = _rawVouchers.any(
          (v) =>
              v.id == uv.voucherId ||
              (v.code == uv.voucherCode && uv.voucherCode.isNotEmpty),
        );
        return (uv.status == 'active' || uv.status == 'available') &&
            !isExpired &&
            hasValidVoucher;
      }).length;
    } else if (filter == VoucherFilter.used) {
      return _rawUserVouchers.where((uv) {
        final hasValidVoucher = _rawVouchers.any(
          (v) =>
              v.id == uv.voucherId ||
              (v.code == uv.voucherCode && uv.voucherCode.isNotEmpty),
        );
        return uv.status == 'used' && hasValidVoucher;
      }).length;
    } else if (filter == VoucherFilter.expired) {
      return _rawUserVouchers.where((uv) {
        final isExpired = uv.expiredAt.isBefore(now);
        final hasValidVoucher = _rawVouchers.any(
          (v) =>
              v.id == uv.voucherId ||
              (v.code == uv.voucherCode && uv.voucherCode.isNotEmpty),
        );
        return (uv.status == 'expired' ||
                ((uv.status == 'active' || uv.status == 'available') &&
                    isExpired)) &&
            hasValidVoucher;
      }).length;
    }
    return 0;
  }

  void retry() => load();

  VoucherModel _fromFirestoreVoucher(store.VoucherModel voucher) {
    final now = DateTime.now();
    final remaining = voucher.expiredAt.difference(now);
    final status = !voucher.isActive || remaining.isNegative
        ? VoucherStatus.expired
        : remaining.inDays <= 3
        ? VoucherStatus.expiringSoon
        : VoucherStatus.available;
    final type = switch (voucher.discountType) {
      'percent' => VoucherType.percentDiscount,
      'freeShipping' => VoucherType.freeShipping,
      'freeItem' => VoucherType.freeItem,
      _ => VoucherType.amountDiscount,
    };
    final valueLabel = switch (type) {
      VoucherType.percentDiscount => 'Giảm ${voucher.discountValue.toInt()}%',
      VoucherType.amountDiscount =>
        '-${formatVoucherMoney(voucher.discountValue.toInt())}',
      VoucherType.freeShipping => 'Freeship',
      VoucherType.freeItem => 'Tặng món',
    };
    final daySpan = voucher.expiredAt.difference(now).inDays;
    return VoucherModel(
      id: voucher.id,
      title: voucher.title,
      code: voucher.code,
      type: type,
      valueLabel: valueLabel,
      description: voucher.description.isNotEmpty
          ? voucher.description
          : valueLabel,
      condition:
          'Đơn tối thiểu ${formatVoucherMoney(voucher.minOrderAmount.toInt())}',
      validFrom: '--',
      validUntil: _formatDate(voucher.expiredAt),
      applicableFoods: const ['Tất cả món đủ điều kiện'],
      remainingUses: status == VoucherStatus.expired ? 0 : 1,
      status: status,
      icon: type == VoucherType.freeShipping
          ? Icons.delivery_dining_outlined
          : Icons.local_activity_outlined,
      expiryProgress: daySpan <= 0 ? 1 : (1 - (daySpan / 30)).clamp(0.08, 1),
      isFeatured: status == VoucherStatus.available,
    );
  }

  VoucherModel? _mergeUserVoucher(store.UserVoucherModel userVoucher) {
    store.VoucherModel? voucher;
    final voucherId = userVoucher.voucherId.trim();
    if (voucherId.isNotEmpty) {
      for (final v in _rawVouchers) {
        if (v.id == voucherId) {
          voucher = v;
          break;
        }
      }
    }
    if (voucher == null) {
      final code = userVoucher.voucherCode.trim();
      if (code.isNotEmpty) {
        for (final v in _rawVouchers) {
          if (v.code == code) {
            voucher = v;
            break;
          }
        }
      }
    }
    if (voucher == null) {
      return null;
    }
    final now = DateTime.now();
    final remaining = userVoucher.expiredAt.difference(now);
    VoucherStatus status;
    if (userVoucher.status == 'used') {
      status = VoucherStatus.used;
    } else if (userVoucher.status == 'expired' || remaining.isNegative) {
      status = VoucherStatus.expired;
    } else if (remaining.inDays <= 3) {
      status = VoucherStatus.expiringSoon;
    } else {
      status = VoucherStatus.available;
    }
    final type = switch (voucher.discountType) {
      'percent' => VoucherType.percentDiscount,
      'freeShipping' => VoucherType.freeShipping,
      'freeItem' => VoucherType.freeItem,
      _ => VoucherType.amountDiscount,
    };
    final valueLabel = switch (type) {
      VoucherType.percentDiscount => 'Giảm ${voucher.discountValue.toInt()}%',
      VoucherType.amountDiscount =>
        '-${formatVoucherMoney(voucher.discountValue.toInt())}',
      VoucherType.freeShipping => 'Freeship',
      VoucherType.freeItem => 'Tặng món',
    };
    final daySpan = userVoucher.expiredAt.difference(now).inDays;
    return VoucherModel(
      id: userVoucher.id,
      title: voucher.title.isNotEmpty
          ? voucher.title
          : (userVoucher.title.isNotEmpty ? userVoucher.title : 'Ưu đãi'),
      code: voucher.code.isNotEmpty ? voucher.code : userVoucher.voucherCode,
      type: type,
      valueLabel: valueLabel,
      description: voucher.description.isNotEmpty
          ? voucher.description
          : (userVoucher.description.isNotEmpty
                ? userVoucher.description
                : valueLabel),
      condition:
          'Đơn tối thiểu ${formatVoucherMoney(voucher.minOrderAmount.toInt())}',
      validFrom: _formatDate(userVoucher.claimedAt),
      validUntil: _formatDate(userVoucher.expiredAt),
      applicableFoods: const ['Tất cả món đủ điều kiện'],
      remainingUses:
          status == VoucherStatus.available ||
              status == VoucherStatus.expiringSoon
          ? 1
          : 0,
      status: status,
      icon: type == VoucherType.freeShipping
          ? Icons.delivery_dining_outlined
          : Icons.local_activity_outlined,
      expiryProgress: daySpan <= 0 ? 1 : (1 - (daySpan / 30)).clamp(0.08, 1),
      isFeatured: status == VoucherStatus.available,
    );
  }

  VoucherModel _voucherFromReward(RewardItemModel reward) {
    return VoucherModel(
      id: 'reward_received',
      title: reward.title,
      code: 'REWARD-${reward.id.toUpperCase()}',
      type: switch (reward.type) {
        RewardType.voucher => VoucherType.amountDiscount,
        RewardType.freeItem => VoucherType.freeItem,
        RewardType.freeShip => VoucherType.freeShipping,
        RewardType.combo => VoucherType.percentDiscount,
      },
      valueLabel: 'Đã đổi thưởng',
      description: reward.description,
      condition: reward.condition,
      validFrom: '26/05/2026',
      validUntil: reward.expiryLabel,
      applicableFoods: const ['Món ăn đủ điều kiện'],
      remainingUses: 1,
      status: VoucherStatus.available,
      icon: reward.icon,
      expiryProgress: 0.08,
      isFeatured: true,
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _vouchersSubscription?.cancel();
    _userVouchersSubscription?.cancel();
    super.dispose();
  }
}

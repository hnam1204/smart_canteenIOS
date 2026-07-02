import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/reward_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/voucher_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import 'reward_model.dart';
import '../vouchers/my_vouchers_screen.dart';
import 'widgets/reward_exchange_widgets.dart';

class RewardPointsController extends SafeChangeNotifier {
  RewardPointsController({
    UserRepository? userRepo,
    VoucherRepository? voucherRepo,
    RewardRepository? rewardRepo,
    this.mockUid,
  })  : _userRepo = userRepo ?? UserRepository(),
        _voucherRepo = voucherRepo ?? VoucherRepository(),
        _rewardRepo = rewardRepo ?? RewardRepository();

  final UserRepository _userRepo;
  final VoucherRepository _voucherRepo;
  final RewardRepository _rewardRepo;
  final String? mockUid;

  RewardPointsModel? _points;
  List<RewardHistoryModel> _history = const [];
  List<RewardItemModel> _rewards = const [];
  RewardHistoryFilter _filter = RewardHistoryFilter.all;
  bool _loading = true;
  final bool _refreshing = false;
  bool _error = false;
  bool _historyError = false;
  bool _disposed = false;

  StreamSubscription<store.UserModel?>? _userSub;
  StreamSubscription<List<store.VoucherModel>>? _vouchersSub;
  StreamSubscription<List<RewardHistoryFirestoreModel>>? _historySub;

  RewardPointsModel get points => _points ?? demoRewardPoints;
  List<MembershipTierModel> get tiers => demoMembershipTiers;
  List<RewardItemModel> get rewards => _rewards;
  List<RewardHistoryModel> get history => _history;
  RewardHistoryFilter get filter => _filter;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get error => _error;
  bool get historyError => _historyError;

  List<RewardHistoryModel> get visibleHistory {
    return _history
        .where((entry) {
          return switch (_filter) {
            RewardHistoryFilter.all => true,
            RewardHistoryFilter.earned =>
              entry.type == RewardHistoryType.earned,
            RewardHistoryFilter.redeemed =>
              entry.type == RewardHistoryType.redeemed,
            RewardHistoryFilter.expired =>
              entry.type == RewardHistoryType.expired,
          };
        })
        .toList(growable: false);
  }

  void load() {
    final hasMock = mockUid != null;
    if (Firebase.apps.isEmpty && !hasMock) {
      _points = demoRewardPoints;
      _history = List<RewardHistoryModel>.of(demoRewardHistory);
      _rewards = List<RewardItemModel>.of(demoRewardItems);
      _loading = false;
      _notify();
      return;
    }

    final uid = mockUid ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser?.uid : null);
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Current UID: ${FirebaseAuth.instance.currentUser?.uid}');
    } else {
      debugPrint('Current UID: $uid');
    }
    if (uid == null) {
      _loading = false;
      _notify();
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').doc(uid).get().then((snap) {
        debugPrint('Collection queried: users');
        debugPrint('Document path: users/${snap.id}');
        debugPrint('Document exists: ${snap.exists}');
        debugPrint('Fields returned: ${snap.data()}');
      }).catchError((Object error, StackTrace stack) {
        debugPrint('users query error: $error');
        final cleaned = StackTrace.fromString(
          stack.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
        );
        debugPrintStack(stackTrace: cleaned);
      });

      FirebaseFirestore.instance.collection('reward_points').doc(uid).get().then((snap) {
        debugPrint('Collection queried: reward_points');
        debugPrint('Document path: reward_points/${snap.id}');
        debugPrint('Document exists: ${snap.exists}');
        debugPrint('Fields returned: ${snap.data()}');
      }).catchError((Object error, StackTrace stack) {
        debugPrint('reward_points query error: $error');
        final cleaned = StackTrace.fromString(
          stack.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
        );
        debugPrintStack(stackTrace: cleaned);
      });

      FirebaseFirestore.instance.collection('reward_histories')
          .where('userId', isEqualTo: uid)
          .get().then((snap) {
        debugPrint('Collection queried: reward_histories');
        debugPrint('Documents count: ${snap.docs.length}');
        for (var doc in snap.docs) {
          debugPrint('Collection queried: reward_histories');
          debugPrint('Document path: reward_histories/${doc.id}');
          debugPrint('Document exists: ${doc.exists}');
          debugPrint('Fields returned: ${doc.data()}');
        }
      }).catchError((Object error, StackTrace stack) {
        debugPrint('reward_histories query error: $error');
        final cleaned = StackTrace.fromString(
          stack.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
        );
        debugPrintStack(stackTrace: cleaned);
      });
    }

    _loading = true;
    _error = false;
    _historyError = false;
    _notify();

    _userSub?.cancel();
    _userSub = _userRepo.watchUser(uid).listen(
      (userModel) {
        if (userModel != null) {
          final pointsVal = userModel.points;
          final currentTier = pointsVal < 500
              ? MembershipTier.bronze
              : pointsVal < 1000
                  ? MembershipTier.silver
                  : pointsVal < 2000
                      ? MembershipTier.gold
                      : MembershipTier.diamond;
          final pointsToNextTier = pointsVal < 500
              ? 500 - pointsVal
              : pointsVal < 1000
                  ? 1000 - pointsVal
                  : pointsVal < 2000
                      ? 2000 - pointsVal
                      : 0;
          final nextTierProgress = pointsVal < 500
              ? pointsVal / 500
              : pointsVal < 1000
                  ? (pointsVal - 500) / 500
                  : pointsVal < 2000
                      ? (pointsVal - 1000) / 1000
                      : 1.0;

          _points = RewardPointsModel(
            availablePoints: pointsVal,
            lifetimePoints: pointsVal + (userModel.totalSpent ~/ 100),
            usedPoints: userModel.totalSpent ~/ 200,
            expiringPoints: 0,
            eligibleOrders: userModel.orderCount,
            currentTier: currentTier,
            pointsToNextTier: pointsToNextTier,
            nextTierProgress: nextTierProgress,
          );
        } else {
          _points = const RewardPointsModel(
            availablePoints: 0,
            lifetimePoints: 0,
            usedPoints: 0,
            expiringPoints: 0,
            eligibleOrders: 0,
            currentTier: MembershipTier.bronze,
            pointsToNextTier: 500,
            nextTierProgress: 0.0,
          );
        }
        _loading = false;
        _notify();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(error.toString());
        final cleaned = StackTrace.fromString(
          stackTrace.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
        );
        debugPrintStack(stackTrace: cleaned);
        _error = true;
        _loading = false;
        _notify();
      },
    );

    _vouchersSub?.cancel();
    _vouchersSub = _voucherRepo.watchVouchers().listen(
      (vouchers) {
        final now = DateTime.now();
        final List<RewardItemModel> mappedRewards = [];

        // filter isExchangeable == true && isActive == true && expiredAt > now
        final exchangeables = vouchers.where((v) =>
            v.isExchangeable && v.isActive && v.expiredAt.isAfter(now));

        for (final v in exchangeables) {
          final remaining = v.claimLimit - v.claimedCount;
          mappedRewards.add(RewardItemModel(
            id: v.id,
            type: RewardType.voucher,
            title: v.title,
            description: v.description,
            condition: 'Đơn tối thiểu ${v.minOrderAmount}đ. Giới hạn 1 voucher/user.',
            pointsRequired: v.exchangePoints,
            expiryLabel: 'Hạn dùng: ${_formatDate(v.expiredAt)}',
            remainingQuantity: remaining.clamp(0, 99999),
            icon: Icons.local_activity_outlined,
            colors: const [Color(0xFFFFE3C8), Color(0xFFFFF5EB)],
          ));
        }

        _rewards = mappedRewards;
        _loading = false;
        _notify();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(error.toString());
        final cleaned = StackTrace.fromString(
          stackTrace.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
        );
        debugPrintStack(stackTrace: cleaned);
        _rewards = const [];
        _notify();
      },
    );

    _historySub?.cancel();
    _historySub = _rewardRepo.watchHistory(uid).listen(
      (histories) {
        _history = histories.map((h) {
          final type = switch (h.type) {
            'redeem' => RewardHistoryType.redeemed,
            'expired' => RewardHistoryType.expired,
            'expiring' => RewardHistoryType.expiring,
            _ => RewardHistoryType.earned,
          };
          final status = switch (h.status) {
            'processing' => RewardStatus.processing,
            'expired' => RewardStatus.expired,
            _ => RewardStatus.success,
          };
          return RewardHistoryModel(
            id: h.id,
            type: type,
            title: h.title,
            points: h.points,
            timeLabel: _formatDate(h.createdAt),
            status: status,
            orderId: h.orderId,
          );
        }).toList();
        _notify();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(error.toString());
        final cleaned = StackTrace.fromString(
          stackTrace.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
        );
        debugPrintStack(stackTrace: cleaned);
        _historyError = true;
        _history = const [];
        _notify();
      },
    );
  }

  Future<void> refresh() async {
    load();
  }

  void setFilter(RewardHistoryFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _notify();
  }

  int countFor(RewardHistoryFilter filter) {
    if (filter == RewardHistoryFilter.all) return _history.length;
    return _history.where((entry) {
      return switch (filter) {
        RewardHistoryFilter.all => true,
        RewardHistoryFilter.earned => entry.type == RewardHistoryType.earned,
        RewardHistoryFilter.redeemed =>
          entry.type == RewardHistoryType.redeemed,
        RewardHistoryFilter.expired => entry.type == RewardHistoryType.expired,
      };
    }).length;
  }

  bool canExchange(RewardItemModel reward) {
    return points.availablePoints >= reward.pointsRequired &&
        reward.remainingQuantity > 0;
  }

  Future<bool> exchangeReward(BuildContext context, RewardItemModel reward) async {
    if (!canExchange(reward)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đủ điểm hoặc quà đã hết.')),
      );
      return false;
    }
    if (Firebase.apps.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (ctx) => ExchangeSuccessDialog(
          reward: reward,
          remainingPoints: points.availablePoints - reward.pointsRequired,
          onViewOffers: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MyVouchersScreen(
                  receivedReward: reward,
                ),
              ),
            );
          },
        ),
      );
      return false;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final result = await _voucherRepo.exchangeVoucher(user.uid, reward.id);
      if (!context.mounted) return false;
      if (result.isSuccess) {
        showDialog<void>(
          context: context,
          builder: (ctx) => ExchangeSuccessDialog(
            reward: reward,
            remainingPoints: points.availablePoints - reward.pointsRequired,
            onViewOffers: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MyVouchersScreen(
                    receivedReward: reward,
                  ),
                ),
              );
            },
          ),
        );
        return false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Đã xảy ra lỗi khi đổi quà.')),
        );
        return false;
      }
    } catch (e, stack) {
      debugPrint('Error exchanging reward in UI: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại.')),
        );
      }
      return false;
    }
  }

  void retry() => load();

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _userSub?.cancel();
    _vouchersSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}

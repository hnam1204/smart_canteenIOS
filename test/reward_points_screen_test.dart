// ignore_for_file: subtype_of_sealed_class
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_canteen/screens/smart_canteen/reward_points/reward_points_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/vouchers/my_vouchers_screen.dart';
import 'package:smart_canteen/models/firestore_models.dart' as store;
import 'package:smart_canteen/repositories/reward_repository.dart';
import 'package:smart_canteen/repositories/user_repository.dart';
import 'package:smart_canteen/repositories/voucher_repository.dart';
import 'package:smart_canteen/screens/smart_canteen/reward_points/reward_points_controller.dart';

void main() {
  testWidgets('reward points loads and exchanges an available reward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: RewardPointsScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Điểm thưởng'), findsOneWidget);
    expect(find.text('1.250 điểm'), findsOneWidget);
    expect(find.text('Hạng thành viên'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reward-item-reward_voucher')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Xác nhận đổi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-reward-exchange')));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Đổi thưởng thành công'), findsOneWidget);
    expect(find.textContaining('Còn 950 điểm'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('view-reward-offers')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(MyVouchersScreen), findsOneWidget);
    expect(find.text('Ưu đãi của tôi'), findsOneWidget);
    expect(find.text('Voucher 30.000đ'), findsOneWidget);
    expect(find.text('Đã đổi thưởng'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reward points remains responsive and filters history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: RewardPointsScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('reward-filter-earned')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Tích điểm từ đơn hàng'), findsWidgets);
    expect(find.text('Điểm đã hết hạn'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  group('Reward points and user mapping fallbacks unit tests', () {
    test('UserModel.fromFirestore fallback mapping for totalOrders', () {
      final snap = FakeDocumentSnapshot({
        'uid': 'user-123',
        'fullName': 'John Doe',
        'email': 'john@example.com',
        'phone': '123456',
        'avatarUrl': '',
        'points': 500,
        'role': 'customer',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 29)),
        'totalOrders': 15,
        'totalSpent': 150000,
        'memberTier': 'Silver',
      });

      final user = store.UserModel.fromFirestore(snap);
      expect(user.orderCount, 15);
      expect(user.toFirestore()['totalOrders'], 15);
    });

    test('RewardHistoryFirestoreModel.fromFirestore fallback mapping for action and reason', () {
      final snapAdd = FakeDocumentSnapshot({
        'id': 'history-1',
        'userId': 'user-123',
        'action': 'add',
        'points': 100,
        'reason': 'Admin points addition',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 29)),
        'status': 'success',
      });

      final historyAdd = RewardHistoryFirestoreModel.fromFirestore(snapAdd);
      expect(historyAdd.type, 'earn');
      expect(historyAdd.title, 'Admin points addition');
      expect(historyAdd.toFirestore()['action'], 'add');
      expect(historyAdd.toFirestore()['reason'], 'Admin points addition');

      final snapDeduct = FakeDocumentSnapshot({
        'id': 'history-2',
        'userId': 'user-123',
        'action': 'deduct',
        'points': 50,
        'reason': 'Points deduction reason',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 29)),
        'status': 'success',
      });

      final historyDeduct = RewardHistoryFirestoreModel.fromFirestore(snapDeduct);
      expect(historyDeduct.type, 'redeem');
      expect(historyDeduct.toFirestore()['action'], 'deduct');
    });

    test('RewardPointsController handles empty histories without error', () async {
      final userRepo = MockUserRepository();
      final voucherRepo = MockVoucherRepository();
      final rewardRepo = MockRewardRepository(throwError: false);

      final controller = RewardPointsController(
        userRepo: userRepo,
        voucherRepo: voucherRepo,
        rewardRepo: rewardRepo,
        mockUid: 'test-uid',
      );

      controller.load();
      await Future<void>.delayed(Duration.zero);

      expect(controller.loading, isFalse);
      expect(controller.error, isFalse);
      expect(controller.historyError, isFalse);
      expect(controller.history.isEmpty, isTrue);
    });

    test('RewardPointsController: history stream error sets historyError, not error', () async {
      final userRepo = MockUserRepository();
      final voucherRepo = MockVoucherRepository();
      final rewardRepo = MockRewardRepository(throwError: true);

      final controller = RewardPointsController(
        userRepo: userRepo,
        voucherRepo: voucherRepo,
        rewardRepo: rewardRepo,
        mockUid: 'test-uid',
      );

      controller.load();
      await Future<void>.delayed(Duration.zero);

      // History error should NOT crash the whole page
      expect(controller.error, isFalse);
      expect(controller.historyError, isTrue);
      expect(controller.history.isEmpty, isTrue);
    });

    test('RewardPointsController: voucher stream error hides vouchers, not whole page', () async {
      final userRepo = MockUserRepository();
      final voucherRepo = MockVoucherRepository(throwError: true);
      final rewardRepo = MockRewardRepository(throwError: false);

      final controller = RewardPointsController(
        userRepo: userRepo,
        voucherRepo: voucherRepo,
        rewardRepo: rewardRepo,
        mockUid: 'test-uid',
      );

      controller.load();
      await Future<void>.delayed(Duration.zero);

      expect(controller.error, isFalse);
      expect(controller.rewards.isEmpty, isTrue);
    });
  });
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot(this._data, {this.id = 'fake-id'});

  final Map<String, dynamic> _data;
  @override
  final String id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserRepository extends Fake implements UserRepository {
  @override
  Stream<store.UserModel?> watchUser(String uid) => Stream.value(store.UserModel(
        uid: uid,
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '123456789',
        avatarUrl: '',
        points: 0,
        role: 'customer',
        createdAt: DateTime(2026, 5, 29),
        totalSpent: 0,
        orderCount: 0,
      ));
}

class MockVoucherRepository extends Fake implements VoucherRepository {
  MockVoucherRepository({this.throwError = false});
  final bool throwError;

  @override
  Stream<List<store.VoucherModel>> watchVouchers() {
    if (throwError) {
      return Stream.error(FirebaseException(
        plugin: 'firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      ));
    }
    return Stream.value(const []);
  }
}

class MockRewardRepository extends Fake implements RewardRepository {
  MockRewardRepository({this.throwError = false});
  final bool throwError;

  @override
  Stream<List<RewardHistoryFirestoreModel>> watchHistory(String userId) {
    if (throwError) {
      return Stream.error(FirebaseException(
        plugin: 'firestore',
        code: 'failed-precondition',
        message: 'The query requires an index.',
      ));
    }
    return Stream.value(const []);
  }
}

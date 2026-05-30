import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_canteen/core/theme/theme_provider.dart';
import 'package:smart_canteen/screens/smart_canteen/activity_history/activity_history_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/all_orders/all_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/delivered_orders/delivered_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/delivering_orders/delivering_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/help_center/help_center_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/notifications/notification_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/pending_orders/pending_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/personal_info/personal_info_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/preparing_orders/preparing_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/profile/profile_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/reward_points/reward_points_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/vouchers/my_vouchers_screen.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget(Widget home) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: MaterialApp(home: home),
    );
  }

  testWidgets('profile loads user data and updates avatar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tài khoản'), findsWidgets);
    expect(find.text('Nguyễn Thảo Vy'), findsOneWidget);
    expect(find.text('1.250 điểm'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.face_3_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile opens notifications and does not overflow on compact phones',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nguyễn Thảo Vy'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byKey(const ValueKey('profile-content-list')),
        const Offset(0, -760),
      );
      await tester.pump();

      expect(find.text('Giới thiệu ngay'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Thông báo'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 720));

      expect(find.text('Đang tải dữ liệu...'), findsNothing);
      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile opens all orders screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('view-all-orders')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AllOrdersScreen), findsOneWidget);
    expect(find.text('Tất cả đơn hàng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile card opens personal info screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Nguyễn Thảo Vy'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PersonalInfoScreen), findsOneWidget);
    expect(find.text('Thông tin cá nhân'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile points card opens reward points screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('1.250 điểm'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(RewardPointsScreen), findsOneWidget);
    expect(find.text('Điểm thưởng'), findsWidgets);
    expect(find.text('Smart Canteen Points'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile offers menu opens vouchers screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Ưu đãi của tôi'));
    await tester.tap(find.text('Ưu đãi của tôi'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(MyVouchersScreen), findsOneWidget);
    expect(find.text('Ưu đãi đặc biệt hôm nay'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile menu opens activity history screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(
      find.byKey(const ValueKey('profile-content-list')),
      const Offset(0, -360),
    );
    await tester.pump();

    await tester.tap(find.text('Lịch sử hoạt động'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(ActivityHistoryScreen), findsOneWidget);
    expect(find.text('Lịch sử hoạt động'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile menu opens help center screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(
      find.byKey(const ValueKey('profile-content-list')),
      const Offset(0, -400),
    );
    await tester.pump();

    await tester.tap(find.text('Trung tâm trợ giúp'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(HelpCenterScreen), findsOneWidget);
    expect(find.text('Trung tâm trợ giúp'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile pending status opens pending orders screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.byKey(const ValueKey('profile-order-status-pending')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PendingOrdersScreen), findsOneWidget);
    expect(find.text('Chờ xác nhận'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile preparing status opens preparing orders screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.byKey(const ValueKey('profile-order-status-preparing')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PreparingOrdersScreen), findsOneWidget);
    expect(find.text('Đang chuẩn bị'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile delivering status opens delivering orders screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.byKey(const ValueKey('profile-order-status-delivering')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DeliveringOrdersScreen), findsOneWidget);
    expect(find.text('Đang giao'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile completed status opens delivered orders screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-450, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('profile-order-status-completed')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DeliveredOrdersScreen), findsOneWidget);
    expect(find.text('Đã giao'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

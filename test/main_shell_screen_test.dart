import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/cart_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/main_shell_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/menu_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/notifications/notification_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/profile/profile_screen.dart';

void main() {
  testWidgets('shell switches tabs immediately and preserves visited pages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Menu').last);
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tài khoản').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Menu').last);
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('Đang tải dữ liệu...'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('profile does not block navigation to the other tabs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: MainShellScreen(initialIndex: 4)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.notifications_none_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    expect(find.byType(NotificationScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byType(MenuScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.shopping_cart_rounded), findsOneWidget);
    expect(find.byType(CartScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}

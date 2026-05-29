import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/all_orders/all_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/all_orders/order_model.dart';
import 'package:smart_canteen/screens/smart_canteen/all_orders/widgets/order_card.dart';
import 'package:smart_canteen/screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/review/review_screen.dart';

void main() {
  testWidgets('all orders searches filters opens details and QR', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: AllOrdersScreen(debugOrders: demoAllOrders)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tất cả đơn hàng'), findsOneWidget);
    expect(find.byType(OrderCard), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('order-search-field')),
      'Đang chuẩn bị',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('SC260525-000152')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260522-000123')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clear-order-search')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('detail-SC260525-000152')));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Tiến trình đơn hàng'), findsOneWidget);
    Navigator.of(tester.element(find.text('Chi tiết đơn hàng'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qr-SC260525-000152')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(QRPickupScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(QRPickupScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-order-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('sheet-order-filter-completed')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed order opens review screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: AllOrdersScreen(
          initialFilter: OrderFilter.completed,
          debugOrders: demoAllOrders,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(
      find.byKey(const ValueKey('review-SC260522-000123')),
    );
    await tester.pump();
    final reviewButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('review-SC260522-000123')),
        matching: find.byType(FilledButton),
      ),
    );
    reviewButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all orders empty state and compact layout do not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: AllOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('order-search-field')),
      'khong-co-don',
    );
    await tester.pump();
    expect(find.text('Bạn chưa có đơn hàng nào'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-order-now')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'order summary collapses smoothly on scroll and restores at top',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: AllOrdersScreen(debugOrders: demoAllOrders)),
      );
      await tester.pump(const Duration(milliseconds: 760));

      final summary = find.byKey(const ValueKey('all-orders-summary-panel'));
      final initialHeight = tester.getSize(summary).height;
      expect(initialHeight, greaterThan(0));
      expect(initialHeight, lessThan(100));

      await tester.drag(
        find.byKey(const ValueKey('all-orders-list')),
        const Offset(0, -180),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.getSize(summary).height, lessThan(1));
      expect(find.byKey(const ValueKey('order-search-field')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('all-orders-filter-tabs')),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey('all-orders-list')),
        const Offset(0, 400),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.getSize(summary).height, closeTo(initialHeight, 1));
      expect(tester.takeException(), isNull);
    },
  );
}

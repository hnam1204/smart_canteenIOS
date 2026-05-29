import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/delivering_orders/delivering_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/delivering_orders/widgets/delivering_order_card.dart';
import 'package:smart_canteen/screens/smart_canteen/review/review_screen.dart';

void main() {
  testWidgets('delivery searches opens contact details and filter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DeliveringOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đơn hàng đang được giao'), findsOneWidget);
    expect(find.byType(DeliveringOrderCard), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('delivery-search-field')),
      'Minh Tuấn',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('SC260525-000156')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260525-000154')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clear-delivery-search')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('delivering-detail-SC260525-000156')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Tiến trình giao hàng'), findsOneWidget);
    Navigator.of(tester.element(find.text('Chi tiết đơn hàng'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('call-shipper-SC260525-000156')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Liên hệ shipper'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-delivery-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delivery-filter-nearby')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('SC260525-000154')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260525-000156')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('delivery completion enables review flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DeliveringOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 4));
    await tester.drag(
      find.byKey(const ValueKey('delivering-orders-list')),
      const Offset(0, -1100),
    );
    await tester.pump();

    expect(find.text('Đã giao'), findsWidgets);
    final reviewButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('delivery-review-SC260525-000151')),
        matching: find.byType(FilledButton),
      ),
    );
    reviewButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('delivery compact empty result has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DeliveringOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delivery-search-field')),
      'khong-co-don',
    );
    await tester.pump();
    expect(find.text('Không có đơn hàng đang giao'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}

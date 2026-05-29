import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/delivered_orders/delivered_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/delivered_orders/widgets/delivered_order_card.dart';
import 'package:smart_canteen/screens/smart_canteen/review/review_screen.dart';

void main() {
  testWidgets('delivered orders searches opens details invoice and filters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DeliveredOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đơn hàng đã giao thành công'), findsOneWidget);
    expect(find.byType(DeliveredOrderCard), findsWidgets);
    expect(find.text('3'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('delivered-search-field')),
      'Minh Tuấn',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('SC260524-000128')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260523-000114')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clear-delivered-search')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('delivered-detail-SC260524-000128')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Tiến trình giao hàng'), findsOneWidget);
    Navigator.of(tester.element(find.text('Chi tiết đơn hàng'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('invoice-SC260524-000128')));
    await tester.pumpAndSettle();
    expect(find.text('Hóa đơn thanh toán'), findsOneWidget);
    expect(find.text('INV-260524-0128'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('download-invoice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-delivered-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('delivered-filter-awaitingReview')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('SC260524-000128')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260523-000114')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivered review and reviewed flows work', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DeliveredOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final addReviewButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('delivered-review-SC260524-000128')),
        matching: find.byType(FilledButton),
      ),
    );
    addReviewButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(ReviewScreen))).pop();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('delivered-orders-list')),
      const Offset(0, -650),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('delivered-review-SC260523-000114')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đánh giá của bạn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivered compact empty result has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DeliveredOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delivered-search-field')),
      'khong-co-don',
    );
    await tester.pump();
    expect(find.text('Chưa có đơn hàng đã giao'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

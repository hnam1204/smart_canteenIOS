import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/preparing_orders/preparing_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/preparing_orders/widgets/preparing_order_card.dart';
import 'package:smart_canteen/screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';

void main() {
  testWidgets('preparing orders searches filters tracks and opens details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PreparingOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Nhà bếp đang chuẩn bị món'), findsOneWidget);
    expect(find.byType(PreparingOrderCard), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('preparing-search-field')),
      'Phở bò',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('SC260525-000146')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260525-000149')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clear-preparing-search')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('preparing-detail-SC260525-000149')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Tiến trình trạng thái'), findsOneWidget);
    Navigator.of(tester.element(find.text('Chi tiết đơn hàng'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('preparing-contact-SC260525-000149')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Liên hệ quầy'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-preparing-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preparing-filter-packing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('SC260525-000146')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC260525-000149')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('preparing countdown enables QR when food becomes ready', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1350));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PreparingOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pump(const Duration(seconds: 4));
    await tester.drag(
      find.byKey(const ValueKey('preparing-orders-list')),
      const Offset(0, -850),
    );
    await tester.pump();

    expect(find.text('Sẵn sàng nhận'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('preparing-qr-SC260525-000143')),
    );
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(QRPickupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('preparing compact empty result has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PreparingOrdersScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('preparing-search-field')),
      'khong-co-don',
    );
    await tester.pump();
    expect(find.text('Không có đơn hàng đang chuẩn bị'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}

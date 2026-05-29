import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/order_history/order_history_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/order_history/widgets/order_history_card.dart';
import 'package:smart_canteen/screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';

void main() {
  testWidgets('history filters orders and opens pickup QR', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: OrderHistoryScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Lịch sử đơn hàng'), findsOneWidget);
    expect(find.byType(OrderHistoryCard), findsWidgets);
    expect(find.byKey(const ValueKey('SC250522-000123')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('history-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-filter-completed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('SC250522-000123')), findsOneWidget);
    expect(find.byKey(const ValueKey('SC250521-000087')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('qr-SC250522-000123')),
    );
    await tester.pump();
    final qrButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('qr-SC250522-000123')),
    );
    qrButton.onPressed!.call();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 530));

    expect(find.text('Đang tải dữ liệu...'), findsNothing);
    expect(find.byType(QRPickupScreen), findsOneWidget);
    expect(find.text('Mã QR nhận món'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history avoids overflow on compact screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: OrderHistoryScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Lịch sử đơn hàng'), findsOneWidget);
    expect(find.byKey(const ValueKey('SC250522-000123')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('order-history-list')),
      const Offset(0, -650),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

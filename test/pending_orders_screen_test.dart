import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/pending_orders/pending_orders_screen.dart';

void main() {
  testWidgets('pending orders shows empty state when Firebase has no session', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PendingOrdersScreen()));
    await tester.pump();

    expect(find.text('Chờ xác nhận'), findsWidgets);
    expect(find.text('Không có đơn hàng chờ xác nhận'), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('pending-search-field')),
      'khong-co-don',
    );
    await tester.pump();
    expect(find.text('Không có đơn hàng chờ xác nhận'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending orders compact empty view fits', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PendingOrdersScreen()));
    await tester.pump();

    expect(find.text('Không có đơn hàng chờ xác nhận'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

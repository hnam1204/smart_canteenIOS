import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/activity_history/activity_history_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/vouchers/my_vouchers_screen.dart';

void main() {
  testWidgets('activity history searches filters and opens detail sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ActivityHistoryScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Lịch sử hoạt động'), findsOneWidget);
    expect(find.text('Đặt món thành công'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('activity-search-field')),
      'PAY-8F21D0',
    );
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(find.text('Đặt món thành công'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clear-activity-search')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('activity-filter-order')));
    await tester.pump(const Duration(milliseconds: 230));
    expect(find.text('Đặt món thành công'), findsOneWidget);
    expect(find.text('Thanh toán thành công'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('activity-detail-act_order_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Xem đơn hàng'), findsOneWidget);
    expect(find.text('SC250525-000126'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('activity filter sheet and compact layout do not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ActivityHistoryScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('open-activity-filters')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Bộ lọc hoạt động'), findsOneWidget);
    expect(find.text('7 ngày gần đây'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('activity-sheet-Loại hoạt động-Thanh toán')),
    );
    await tester.tap(find.byKey(const ValueKey('apply-activity-filter')));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(find.text('Thanh toán thất bại'), findsOneWidget);
    expect(find.text('Đặt món thành công'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('activity offer detail opens vouchers screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ActivityHistoryScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.byKey(const ValueKey('open-activity-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ưu đãi').last);
    await tester.tap(find.byKey(const ValueKey('apply-activity-filter')));
    await tester.pumpAndSettle();

    expect(find.text('Sử dụng voucher'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('activity-detail-act_offer_1')));
    await tester.pumpAndSettle();
    expect(find.text('Khám phá ưu đãi'), findsOneWidget);

    await tester.tap(find.text('Khám phá ưu đãi'));
    await tester.pumpAndSettle();

    expect(find.byType(MyVouchersScreen), findsOneWidget);
    expect(find.text('Ưu đãi của tôi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

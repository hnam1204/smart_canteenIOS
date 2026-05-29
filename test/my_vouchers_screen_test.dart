import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/vouchers/my_vouchers_screen.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('vouchers searches copies and opens detail sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MyVouchersScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Ưu đãi của tôi'), findsOneWidget);
    expect(find.text('Ưu đãi đặc biệt hôm nay'), findsOneWidget);
    expect(find.text('Ưu đãi bữa trưa - giảm 20%'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('voucher-search-field')),
      'FRESH20',
    );
    await tester.pump();
    expect(find.text('Ưu đãi bữa trưa - giảm 20%'), findsOneWidget);
    expect(find.text('Freeship trong campus'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('copy-voucher-voucher_featured')),
    );
    await tester.pump();
    expect(find.text('Đã sao chép mã ưu đãi.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('detail-voucher-voucher_featured')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết ưu đãi'), findsOneWidget);
    expect(find.byKey(const ValueKey('voucher-detail-code')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vouchers filters and remains responsive on compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MyVouchersScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    await tester.drag(
      find.byKey(const ValueKey('voucher-filter-tabs')),
      const Offset(-190, 0),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('voucher-filter-mine')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Giảm 15% món yêu thích'), findsOneWidget);
    expect(find.text('Freeship trong campus'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('use-voucher-voucher_lunch')));
    await tester.pump();
    expect(
      find.text('Đơn hàng chưa đủ điều kiện áp dụng mã này.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/payment_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';

void main() {
  testWidgets('payment offers only cash and VietQR transfer methods', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));

    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text('Tiền mặt tại quầy'), findsOneWidget);
    expect(find.text('Chuyển khoản ngân hàng'), findsOneWidget);
    expect(find.text('ZaloPay'), findsNothing);
    expect(find.text('MoMo'), findsNothing);
    expect(find.textContaining('ATM'), findsNothing);
    expect(
      find.text('Vui lòng thanh toán tại quầy khi nhận món'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bank QR displays transfer information and can copy it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.tap(find.byKey(const ValueKey('payment-method-bankQr')));
    await tester.pump(const Duration(milliseconds: 280));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('copy-bank-account')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Thanh toán VietQR'), findsOneWidget);
    expect(find.text('MB BANK'), findsOneWidget);
    expect(find.text('Nguyễn Hải Nam'), findsOneWidget);
    expect(find.text('195989'), findsOneWidget);
    expect(find.text('ThanhToanSC250522000123'), findsOneWidget);
    expect(find.text('QR hết hạn sau 10:00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('copy-bank-account')));
    await tester.pump();
    expect(find.text('Đã sao chép số tài khoản.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('bank transfer can send manual review request without checkout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1450));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.tap(find.byKey(const ValueKey('payment-method-bankQr')));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('confirm-payment')), findsNothing);
    expect(
      find.byKey(const ValueKey('manual-transfer-confirm')),
      findsOneWidget,
    );
    expect(find.byType(QRPickupScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('manual-transfer-confirm')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Xác nhận đã chuyển khoản?'), findsOneWidget);

    await tester.tap(find.text('Hủy'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã gửi yêu cầu xác nhận'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('manual-transfer-confirm')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tôi đã chuyển khoản'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đã gửi yêu cầu xác nhận'), findsOneWidget);
    expect(find.text('Đang chờ admin xác nhận'), findsOneWidget);
    expect(find.byType(QRPickupScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cash confirmation opens pickup QR with cash status', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.tap(find.byKey(const ValueKey('confirm-payment')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byType(QRPickupScreen), findsOneWidget);
    expect(find.textContaining('Thanh toán tại quầy'), findsWidgets);
    expect(find.text('MB BANK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment layout does not overflow on compact iPhone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('payment-method-bankQr')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byKey(const ValueKey('payment-content-list')),
      const Offset(0, -160),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('payment-method-bankQr')));
    await tester.pump(const Duration(milliseconds: 280));

    expect(find.byKey(const ValueKey('vietqr-payment-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pickup QR after payment stays responsive on compact width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.tap(find.byKey(const ValueKey('confirm-payment')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byType(QRPickupScreen), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('qr-content-list')),
      const Offset(0, -1000),
    );
    await tester.pump();
    expect(find.text('Lưu ý'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

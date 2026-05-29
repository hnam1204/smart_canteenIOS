import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_canteen/screens/smart_canteen/qr_pickup/order_model.dart';
import 'package:smart_canteen/screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';

void main() {
  testWidgets(
    'pickup QR displays verified preview and reloads without fake token',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
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

      await tester.pumpWidget(
        const MaterialApp(
          home: QRPickupScreen(
            orderId: 'SC250522-000123',
            previewOrder: demoPickupOrder,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Mã QR nhận món'), findsOneWidget);
      expect(find.text('SC250522-000123'), findsOneWidget);
      expect(find.text('Đã thanh toán'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      expect(
        find.byKey(const ValueKey('preview:SC250522-000123')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('copy-order-id')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.textContaining('Đã sao chép mã đơn hàng'), findsOneWidget);

      await tester.tap(find.text('Tải lại mã nhận món'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('preview:SC250522-000123')),
        findsOneWidget,
      );
      expect(find.text('Tải lại mã nhận món'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pickup QR remains responsive on compact screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: QRPickupScreen(
          orderId: 'SC250522-000123',
          previewOrder: demoPickupOrder,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('qr-content-list')),
      const Offset(0, -1000),
    );
    await tester.pump();

    expect(find.text('Thông tin đơn hàng'), findsOneWidget);
    expect(find.text('Lưu ý'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pickup QR rejects an order without verified payment', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: QRPickupScreen(orderId: 'unverified-order')),
    );
    await tester.pump();

    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('Không thể xác minh đơn hàng'), findsOneWidget);
  });
}

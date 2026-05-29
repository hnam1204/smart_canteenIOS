import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/all_orders/all_orders_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/help_center/help_center_screen.dart';

void main() {
  testWidgets('help center searches faq expands item and opens chat', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Trung tâm trợ giúp'), findsOneWidget);
    expect(find.text('Chúng tôi có thể giúp gì cho bạn?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('help-search-field')),
      'mật khẩu',
    );
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('Làm sao đổi mật khẩu?'), findsOneWidget);
    expect(find.text('Làm sao để đặt món?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('faq-faq_password')));
    await tester.pump(const Duration(milliseconds: 230));
    expect(find.textContaining('Bảo mật tài khoản'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-chat-support')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ChatSupportScreen), findsOneWidget);
    expect(find.text('Hỗ trợ viên đang trực tuyến'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('help center submits and views ticket on compact layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: HelpCenterScreen(key: ValueKey('tracking-help-center')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('help-content-list')),
      const Offset(0, -1200),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('problem-description-field')),
      'Ứng dụng không hiển thị trạng thái đơn vừa đặt.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('attach-problem-image')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('attach-problem-image')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-support-ticket')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-support-ticket')));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Yêu cầu hỗ trợ đã được gửi thành công.'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('help-content-list')),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(find.text('Xem chi tiết').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Đóng ticket'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('help center quick support routes and scrolls to contact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.byKey(const ValueKey('support-action-contact')));
    await tester.pumpAndSettle();
    expect(find.text('Hỗ trợ Smart Canteen'), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-chat')), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: HelpCenterScreen(key: ValueKey('tracking-help-center')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey('support-action-trackOrder')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(AllOrdersScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('help center opens refund policy from quick action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.byKey(const ValueKey('support-action-refundPolicy')));
    await tester.pumpAndSettle();
    expect(find.byType(RefundPolicyScreen), findsOneWidget);
    expect(find.text('Chính sách hoàn tiền'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

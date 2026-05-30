import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/help_center/help_center_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/help_center/support_chat_screen.dart';

void main() {
  testWidgets('help center loads and displays problem form and ticket list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Trung tâm trợ giúp'), findsWidgets);
    expect(find.text('Tạo yêu cầu hỗ trợ'), findsOneWidget);
    expect(find.text('Yêu cầu của tôi'), findsOneWidget);
    
    // Check that fallback demo tickets are displayed
    expect(find.text('Thanh toán bị trừ tiền hai lần'), findsOneWidget);
    expect(find.text('Thiếu món trong đơn hàng'), findsOneWidget);
  });

  testWidgets('help center submits ticket and opens chat screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));

    // Fill problem description
    await tester.enterText(
      find.byKey(const ValueKey('problem-description-field')),
      'Đơn hàng bị giao trễ hơn 30 phút.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    tester.testTextInput.hide();
    await tester.pump();

    // Submit ticket
    await tester.tap(find.byKey(const ValueKey('submit-support-ticket')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đã gửi yêu cầu hỗ trợ'), findsOneWidget);

    // Click "Chat ngay" on the newly created ticket
    await tester.tap(find.text('Chat ngay').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Should open SupportChatScreen
    expect(find.byType(SupportChatScreen), findsOneWidget);
    expect(find.text('Đơn hàng cần hỗ trợ'), findsOneWidget);
    expect(find.text('Nhập tin nhắn...'), findsOneWidget);
    
    // Send a message inside chat
    await tester.enterText(find.byType(TextField), 'Vui lòng kiểm tra giúp.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    
    expect(find.text('Vui lòng kiểm tra giúp.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_canteen/screens/smart_canteen/main_shell_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/notifications/notification_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('main navigation switches tabs without a blocking loader', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));

    await tester.tap(find.text('Thông báo').last);
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NotificationScreen), findsOneWidget);
    expect(find.text('Đang tải dữ liệu...'), findsNothing);
  });
}

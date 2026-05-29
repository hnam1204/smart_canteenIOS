import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_canteen/main.dart';
import 'package:smart_canteen/screens/auth/login_screen.dart';

void main() {
  testWidgets('App initializes with Login Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      SmartCanteenApp(authStateChanges: Stream<User?>.value(null)),
    );
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsWidgets);
  });
}

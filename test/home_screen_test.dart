import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/core/widgets/mini_app_item.dart';
import 'package:smart_canteen/screens/home/home_screen.dart';
import 'package:smart_canteen/screens/splash/splash_screen.dart';

void main() {
  testWidgets('canteen shortcut opens splash before smart canteen home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('open-smart-canteen')),
    );
    await tester.pump();
    final shortcut = tester.widget<MiniAppItem>(
      find.byKey(const ValueKey('open-smart-canteen')),
    );
    shortcut.onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.text('Không thể mở Smart Canteen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

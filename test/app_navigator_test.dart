import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/core/navigation/app_navigator.dart';

void main() {
  testWidgets('navigation opens destination without artificial loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppNavigator.push<void>(
                context,
                builder: (_) => const Scaffold(body: Text('Destination')),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Đang tải dữ liệu...'), findsNothing);
    expect(find.text('Destination'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

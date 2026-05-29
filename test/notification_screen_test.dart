import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/notifications/notification_screen.dart';
import 'package:smart_canteen/screens/smart_canteen/notifications/widgets/notification_card.dart';

void main() {
  testWidgets('notification screen filters and marks all notifications read', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: NotificationScreen()));

    expect(find.text('Thông báo'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Ưu đãi đặc biệt dành cho bạn!'), findsOneWidget);

    await tester.tap(find.text('Ưu đãi'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationCard), findsNWidgets(2));

    await tester.tap(find.text('Đánh dấu tất cả đã đọc'));
    await tester.pump();

    expect(find.text('Tất cả đã đọc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification screen does not overflow on compact phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: NotificationScreen()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Thông báo'), findsWidgets);
    expect(find.text('Ưu đãi đặc biệt dành cho bạn!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

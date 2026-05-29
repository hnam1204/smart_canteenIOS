import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/personal_info/personal_info_screen.dart';

void main() {
  testWidgets('personal info shows auth required state without Firebase user', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PersonalInfoScreen()));
    await tester.pump();

    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Vui lòng đăng nhập'), findsOneWidget);
    expect(
      find.text('Bạn cần đăng nhập để xem và cập nhật thông tin cá nhân.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('personal info auth required view fits compact screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PersonalInfoScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.lock_person_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

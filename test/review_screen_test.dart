import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/review/review_screen.dart';

void main() {
  testWidgets('review supports rating tags images validation and submit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ReviewScreen()));

    expect(find.text('Đánh giá'), findsOneWidget);
    expect(find.textContaining('SC250522-000123'), findsOneWidget);
    expect(find.text('Đã hoàn thành'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rating-star-2')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('Không hài lòng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-tag-delicious')));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('submit-review-button')),
      260,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('review-content-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('submit-review-button')));
    await tester.pump();
    expect(
      find.text('Vui lòng chia sẻ lý do khi đánh giá dưới 3 sao.'),
      findsWidgets,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('review-comment-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('review-comment-field')),
      'Món hơi nguội, cần cải thiện thời gian phục vụ.',
    );
    await tester.tap(find.byKey(const ValueKey('add-review-image')));
    await tester.pump();
    expect(find.byKey(const ValueKey('remove-review-image-1')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('submit-review-button')),
      260,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('review-content-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('submit-review-button')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Cảm ơn đánh giá của bạn!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-history-button')));
    await tester.pumpAndSettle();
    expect(find.text('Lịch sử đánh giá'), findsOneWidget);
    expect(find.text('SC250522-000123'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review remains usable on compact screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ReviewScreen()));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('rating-star-5')));
    await tester.pump();
    expect(find.text('Tuyệt vời'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('submit-review-button')),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('review-content-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('submit-review-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

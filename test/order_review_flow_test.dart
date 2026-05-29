import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/screens/smart_canteen/order_history/order_model.dart' as history;
import 'package:smart_canteen/screens/smart_canteen/order_history/widgets/order_history_card.dart';
import 'package:smart_canteen/screens/smart_canteen/review/review_screen.dart';
import 'package:smart_canteen/models/firestore_models.dart' as store;

void main() {
  group('Order History and Review Flow Tests', () {
    test('history status mapping maps delivered and administrative completed states', () {
      final orderDelivered = mapFromFirestore(
        store.OrderModel(
          id: 'order-1',
          userId: 'user-1',
          orderCode: 'SC001',
          items: const [],
          totalAmount: 10000,
          paymentMethod: 'cash',
          paymentStatus: 'paid',
          orderStatus: 'delivered',
          pickupCounter: 'Quầy A',
          note: '',
          createdAt: DateTime(2026, 5, 29),
          updatedAt: DateTime(2026, 5, 29),
          pickupEnabled: true,
        ),
      );
      expect(orderDelivered.status, history.OrderHistoryStatus.delivered);

      final orderSuccess = mapFromFirestore(
        store.OrderModel(
          id: 'order-2',
          userId: 'user-1',
          orderCode: 'SC002',
          items: const [],
          totalAmount: 20000,
          paymentMethod: 'cash',
          paymentStatus: 'paid',
          orderStatus: 'success',
          pickupCounter: 'Quầy A',
          note: '',
          createdAt: DateTime(2026, 5, 29),
          updatedAt: DateTime(2026, 5, 29),
          pickupEnabled: true,
        ),
      );
      expect(orderSuccess.status, history.OrderHistoryStatus.completed);
    });

    testWidgets('delivered or completed order shows review button, pending/preparing does not', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final deliveredOrder = history.OrderModel(
        id: 'SC001',
        date: '29/05/2026',
        time: '10:00',
        status: history.OrderHistoryStatus.delivered,
        items: [
          const history.OrderItemModel(name: 'Cơm tấm', quantity: 1, price: 30000, imageAsset: ''),
        ],
        pickupEnabled: true,
        paymentStatus: 'paid',
        paymentMethod: 'cash',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OrderHistoryCard(
            order: deliveredOrder,
            onDetailsTap: () {},
            onQrTap: () {},
            onReviewTap: () {},
          ),
        ),
      ));

      expect(find.byKey(const ValueKey('review-SC001')), findsOneWidget);
      expect(find.text('Đánh giá'), findsOneWidget);

      final pendingOrder = history.OrderModel(
        id: 'SC002',
        date: '29/05/2026',
        time: '10:15',
        status: history.OrderHistoryStatus.pending,
        items: [
          const history.OrderItemModel(name: 'Phở', quantity: 1, price: 35000, imageAsset: ''),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OrderHistoryCard(
            order: pendingOrder,
            onDetailsTap: () {},
            onQrTap: () {},
            onReviewTap: () {},
          ),
        ),
      ));

      expect(find.byKey(const ValueKey('review-SC002')), findsNothing);
      expect(find.text('Đánh giá'), findsNothing);
    });

    testWidgets('reviewed order shows Da danh gia and is disabled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final reviewedOrder = history.OrderModel(
        id: 'SC003',
        date: '29/05/2026',
        time: '10:30',
        status: history.OrderHistoryStatus.completed,
        items: [
          const history.OrderItemModel(name: 'Bún chả', quantity: 1, price: 40000, imageAsset: ''),
        ],
        hasReview: true,
        pickupEnabled: false,
      );

      bool tapTriggered = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OrderHistoryCard(
            order: reviewedOrder,
            onDetailsTap: () {},
            onQrTap: () {},
            onReviewTap: () {
              tapTriggered = true;
            },
          ),
        ),
      ));

      final reviewButtonFinder = find.byKey(const ValueKey('review-SC003'));
      expect(reviewButtonFinder, findsOneWidget);
      expect(find.text('Đã đánh giá'), findsOneWidget);

      await tester.tap(reviewButtonFinder);
      await tester.pump();
      expect(tapTriggered, isFalse);
    });

    testWidgets('ReviewScreen supports optional orderId constructor and falls back', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ReviewScreen(orderId: 'SC250522-000123'),
      ));
      expect(find.text('Đánh giá'), findsOneWidget);
    });
  group('Delivered/Completed Tab query filter testing', () {
    test('history status filter delivered + completed is matched', () {
      final deliversMatch = mapFromFirestore(
        store.OrderModel(
          id: 'order-3',
          userId: 'user-1',
          orderCode: 'SC003',
          items: const [],
          totalAmount: 10000,
          paymentMethod: 'cash',
          paymentStatus: 'paid',
          orderStatus: 'delivered',
          pickupCounter: 'Quầy A',
          note: '',
          createdAt: DateTime(2026, 5, 29),
          updatedAt: DateTime(2026, 5, 29),
          pickupEnabled: true,
        ),
      );
      final completesMatch = mapFromFirestore(
        store.OrderModel(
          id: 'order-4',
          userId: 'user-1',
          orderCode: 'SC004',
          items: const [],
          totalAmount: 10000,
          paymentMethod: 'cash',
          paymentStatus: 'paid',
          orderStatus: 'completed',
          pickupCounter: 'Quầy A',
          note: '',
          createdAt: DateTime(2026, 5, 29),
          updatedAt: DateTime(2026, 5, 29),
          pickupEnabled: true,
        ),
      );
      expect(deliversMatch.status, history.OrderHistoryStatus.delivered);
      expect(completesMatch.status, history.OrderHistoryStatus.completed);
    });
  });
  });
}

history.OrderModel mapFromFirestore(store.OrderModel order) {
  final created = order.createdAt;
  String two(int value) => value.toString().padLeft(2, '0');
  final status = switch (order.orderStatus.trim()) {
    'pending' => history.OrderHistoryStatus.pending,
    'preparing' => history.OrderHistoryStatus.preparing,
    'ready' || 'delivering' || 'readyForPickup' => history.OrderHistoryStatus.delivering,
    'delivered' => history.OrderHistoryStatus.delivered,
    'completed' || 'done' || 'success' || 'finished' || 'complete' => history.OrderHistoryStatus.completed,
    'cancelled' => history.OrderHistoryStatus.cancelled,
    _ => history.OrderHistoryStatus.completed,
  };
  return history.OrderModel(
    id: order.orderCode.isEmpty ? order.id : order.orderCode,
    date: '${two(created.day)}/${two(created.month)}/${created.year}',
    time: '${two(created.hour)}:${two(created.minute)}',
    status: status,
    pickupCounter: order.pickupCounter,
    readyAt: status == history.OrderHistoryStatus.preparing ? 'Đang cập nhật' : null,
    hasReview: order.hasReview,
    firestoreId: order.id,
    pickupEnabled: order.pickupEnabled,
    paymentStatus: order.paymentStatus,
    paymentMethod: order.paymentMethod,
    items: order.items
        .map(
          (item) => history.OrderItemModel(
            name: item.name,
            quantity: item.quantity,
            price: item.total ~/ item.quantity,
            imageAsset: item.imageUrl,
          ),
        )
        .toList(growable: false),
  );
}

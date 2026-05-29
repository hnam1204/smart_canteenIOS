enum OrderStatus {
  pending,
  preparing,
  delivering,
  delivered,
  completed,
  cancelled,
}

enum OrderFilter { all, pending, preparing, delivering, completed, cancelled }

enum PaymentStatus { pending, unpaid, paid, failed, expired, refunded }

class OrderItemModel {
  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageAsset,
  });

  final String name;
  final int quantity;
  final int price;
  final String imageAsset;

  int get total => quantity * price;
}

class OrderTimelineEvent {
  const OrderTimelineEvent({
    required this.title,
    required this.time,
    this.completed = true,
  });

  final String title;
  final String time;
  final bool completed;
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderedAt,
    required this.status,
    required this.paymentStatus,
    required this.pickupCounter,
    required this.items,
    required this.timeline,
    this.totalAmount = 0,
    this.note,
    this.paymentMethod = 'cash',
    this.pickupEnabled = false,
    this.hasReview = false,
  });

  final String id;
  final String orderedAt;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String pickupCounter;
  final List<OrderItemModel> items;
  final List<OrderTimelineEvent> timeline;
  final int totalAmount;
  final String? note;
  final String paymentMethod;
  final bool pickupEnabled;
  final bool hasReview;

  int get total => totalAmount > 0
      ? totalAmount
      : items.fold<int>(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  OrderModel copyWith({OrderStatus? status, PaymentStatus? paymentStatus, bool? hasReview}) {
    return OrderModel(
      id: id,
      orderedAt: orderedAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      pickupCounter: pickupCounter,
      items: items,
      timeline: timeline,
      totalAmount: totalAmount,
      note: note,
      paymentMethod: paymentMethod,
      pickupEnabled: pickupEnabled,
      hasReview: hasReview ?? this.hasReview,
    );
  }
}

const demoAllOrders = <OrderModel>[
  OrderModel(
    id: 'SC260525-000152',
    orderedAt: '25/05/2026 - 10:05',
    status: OrderStatus.preparing,
    paymentStatus: PaymentStatus.pending,
    pickupCounter: 'Quay A',
    paymentMethod: 'bankQr',
    pickupEnabled: true,
    note: 'It cay, lay them muong.',
    items: [
      OrderItemModel(
        name: 'Com ga xoi mo',
        quantity: 1,
        price: 32000,
        imageAsset: 'assets/images/chicken_rice.jpg',
      ),
      OrderItemModel(
        name: 'Tra tac',
        quantity: 1,
        price: 12000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
    timeline: [
      OrderTimelineEvent(title: 'Dat mon thanh cong', time: '10:05'),
      OrderTimelineEvent(title: 'Cho xac nhan chuyen khoan', time: '10:06'),
      OrderTimelineEvent(title: 'Dang chuan bi', time: '10:08'),
    ],
  ),
  OrderModel(
    id: 'SC260525-000141',
    orderedAt: '25/05/2026 - 08:50',
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
    pickupCounter: 'Quay A',
    paymentMethod: 'cash',
    pickupEnabled: true,
    items: [
      OrderItemModel(
        name: 'Mi xao hai san',
        quantity: 1,
        price: 35000,
        imageAsset: 'assets/images/salad.jpg',
      ),
    ],
    timeline: [
      OrderTimelineEvent(title: 'Dat mon thanh cong', time: '08:50'),
      OrderTimelineEvent(
        title: 'Cho xac nhan',
        time: 'Dang xu ly',
        completed: false,
      ),
    ],
  ),
  OrderModel(
    id: 'SC260522-000123',
    orderedAt: '22/05/2026 - 09:30',
    status: OrderStatus.completed,
    paymentStatus: PaymentStatus.paid,
    pickupCounter: 'Quay A',
    paymentMethod: 'bankQr',
    pickupEnabled: false,
    items: [
      OrderItemModel(
        name: 'Com ga xoi mo',
        quantity: 1,
        price: 32000,
        imageAsset: 'assets/images/chicken_rice.jpg',
      ),
      OrderItemModel(
        name: 'Tra tac',
        quantity: 1,
        price: 12000,
        imageAsset: 'assets/images/pho.jpg',
      ),
      OrderItemModel(
        name: 'Banh flan',
        quantity: 1,
        price: 10000,
        imageAsset: 'assets/images/salad.jpg',
      ),
    ],
    timeline: [
      OrderTimelineEvent(title: 'Dat mon thanh cong', time: '09:30'),
      OrderTimelineEvent(title: 'Da nhan mon', time: '09:49'),
    ],
  ),
  OrderModel(
    id: 'SC260521-000087',
    orderedAt: '21/05/2026 - 12:05',
    status: OrderStatus.cancelled,
    paymentStatus: PaymentStatus.refunded,
    pickupCounter: 'Quay B',
    paymentMethod: 'cash',
    pickupEnabled: false,
    items: [
      OrderItemModel(
        name: 'Bun bo Hue',
        quantity: 1,
        price: 36000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
    timeline: [
      OrderTimelineEvent(title: 'Dat mon thanh cong', time: '12:05'),
      OrderTimelineEvent(title: 'Da huy don', time: '12:09'),
    ],
  ),
];

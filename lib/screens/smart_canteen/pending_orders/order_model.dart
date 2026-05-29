enum OrderStatus { pending }

enum PaymentMethod { cash, bankQr }

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

  int get total => price * quantity;
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
    required this.waitingTime,
    required this.paymentMethod,
    required this.pickupCounter,
    required this.items,
    required this.timeline,
    this.status = OrderStatus.pending,
    this.note,
  });

  final String id;
  final String orderedAt;
  final Duration waitingTime;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String pickupCounter;
  final List<OrderItemModel> items;
  final List<OrderTimelineEvent> timeline;
  final String? note;

  int get total => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

String formatCurrency(int value) {
  final digits = value.toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) formatted.write('.');
    formatted.write(digits[index]);
  }
  formatted.write('đ');
  return formatted.toString();
}

String paymentMethodLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => 'Tiền mặt tại quầy',
    PaymentMethod.bankQr => 'Chuyển khoản ngân hàng',
  };
}

const demoPendingOrders = <OrderModel>[
  OrderModel(
    id: 'SC260525-000141',
    orderedAt: '25/05/2026 - 10:21',
    waitingTime: Duration(minutes: 3, seconds: 25),
    paymentMethod: PaymentMethod.cash,
    pickupCounter: 'Quầy A',
    note: 'Ít cay, không hành.',
    items: [
      OrderItemModel(
        name: 'Cơm gà xối mỡ',
        quantity: 1,
        price: 32000,
        imageAsset: 'assets/images/chicken_rice.jpg',
      ),
      OrderItemModel(
        name: 'Trà tắc',
        quantity: 1,
        price: 12000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
    timeline: [
      OrderTimelineEvent(title: 'Đặt món thành công', time: '10:21'),
      OrderTimelineEvent(
        title: 'Chờ nhà bếp xác nhận',
        time: 'Đang xử lý',
        completed: false,
      ),
    ],
  ),
  OrderModel(
    id: 'SC260525-000138',
    orderedAt: '25/05/2026 - 10:12',
    waitingTime: Duration(minutes: 11, seconds: 15),
    paymentMethod: PaymentMethod.bankQr,
    pickupCounter: 'Quầy B',
    items: [
      OrderItemModel(
        name: 'Phở bò đặc biệt',
        quantity: 1,
        price: 38000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
    timeline: [
      OrderTimelineEvent(title: 'Đặt món thành công', time: '10:12'),
      OrderTimelineEvent(title: 'Đã thanh toán', time: '10:12'),
      OrderTimelineEvent(
        title: 'Chờ nhà bếp xác nhận',
        time: 'Đang chậm hơn dự kiến',
        completed: false,
      ),
    ],
  ),
];

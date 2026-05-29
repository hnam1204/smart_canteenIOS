enum OrderStatus { delivered }

enum PaymentMethod { bankQr, cash }

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

class DeliveryInfoModel {
  const DeliveryInfoModel({
    required this.shipperName,
    required this.phone,
    required this.destination,
    required this.avatarSeed,
  });

  final String shipperName;
  final String phone;
  final String destination;
  final int avatarSeed;
}

class DeliveredTimelineEvent {
  const DeliveredTimelineEvent({required this.title, required this.time});

  final String title;
  final String time;
}

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.paidAt,
    required this.discount,
  });

  final String id;
  final String paidAt;
  final int discount;
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderedAt,
    required this.deliveredAt,
    required this.paymentMethod,
    required this.items,
    required this.delivery,
    required this.timeline,
    required this.invoice,
    required this.rewardPoints,
    this.reviewed = false,
    this.note,
    this.status = OrderStatus.delivered,
  });

  final String id;
  final String orderedAt;
  final String deliveredAt;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final List<OrderItemModel> items;
  final DeliveryInfoModel delivery;
  final List<DeliveredTimelineEvent> timeline;
  final InvoiceModel invoice;
  final int rewardPoints;
  final bool reviewed;
  final String? note;

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get total => subtotal - invoice.discount;
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
    PaymentMethod.bankQr => 'Chuyển khoản ngân hàng',
    PaymentMethod.cash => 'Tiền mặt',
  };
}

const demoDeliveredOrders = <OrderModel>[
  OrderModel(
    id: 'SC260524-000128',
    orderedAt: '24/05/2026 - 11:25',
    deliveredAt: '24/05/2026 - 11:48',
    paymentMethod: PaymentMethod.bankQr,
    rewardPoints: 52,
    note: 'Giao tại sảnh thư viện.',
    delivery: DeliveryInfoModel(
      shipperName: 'Minh Tuấn',
      phone: '0909 246 810',
      destination: 'Sảnh thư viện - Khu A',
      avatarSeed: 0,
    ),
    invoice: InvoiceModel(
      id: 'INV-260524-0128',
      paidAt: '24/05/2026 - 11:26',
      discount: 4000,
    ),
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
      DeliveredTimelineEvent(title: 'Đã đặt hàng', time: '11:25'),
      DeliveredTimelineEvent(title: 'Đã xác nhận', time: '11:27'),
      DeliveredTimelineEvent(title: 'Đang chuẩn bị', time: '11:29'),
      DeliveredTimelineEvent(title: 'Đang giao', time: '11:40'),
      DeliveredTimelineEvent(title: 'Đã giao', time: '11:48'),
    ],
  ),
  OrderModel(
    id: 'SC260523-000114',
    orderedAt: '23/05/2026 - 12:03',
    deliveredAt: '23/05/2026 - 12:24',
    paymentMethod: PaymentMethod.bankQr,
    rewardPoints: 48,
    reviewed: true,
    delivery: DeliveryInfoModel(
      shipperName: 'Hoàng Nam',
      phone: '0912 678 345',
      destination: 'Tòa nhà B - Tầng 1',
      avatarSeed: 1,
    ),
    invoice: InvoiceModel(
      id: 'INV-260523-0114',
      paidAt: '23/05/2026 - 12:04',
      discount: 0,
    ),
    items: [
      OrderItemModel(
        name: 'Phở bò đặc biệt',
        quantity: 1,
        price: 38000,
        imageAsset: 'assets/images/pho.jpg',
      ),
      OrderItemModel(
        name: 'Bánh flan',
        quantity: 1,
        price: 10000,
        imageAsset: 'assets/images/salad.jpg',
      ),
    ],
    timeline: [
      DeliveredTimelineEvent(title: 'Đã đặt hàng', time: '12:03'),
      DeliveredTimelineEvent(title: 'Đã xác nhận', time: '12:05'),
      DeliveredTimelineEvent(title: 'Đang chuẩn bị', time: '12:08'),
      DeliveredTimelineEvent(title: 'Đang giao', time: '12:18'),
      DeliveredTimelineEvent(title: 'Đã giao', time: '12:24'),
    ],
  ),
  OrderModel(
    id: 'SC260522-000101',
    orderedAt: '22/05/2026 - 09:30',
    deliveredAt: '22/05/2026 - 09:51',
    paymentMethod: PaymentMethod.cash,
    rewardPoints: 35,
    delivery: DeliveryInfoModel(
      shipperName: 'Anh Khoa',
      phone: '0988 110 220',
      destination: 'Ký túc xá C - Cổng chính',
      avatarSeed: 2,
    ),
    invoice: InvoiceModel(
      id: 'INV-260522-0101',
      paidAt: '22/05/2026 - 09:51',
      discount: 0,
    ),
    items: [
      OrderItemModel(
        name: 'Mì xào hải sản',
        quantity: 1,
        price: 35000,
        imageAsset: 'assets/images/salad.jpg',
      ),
    ],
    timeline: [
      DeliveredTimelineEvent(title: 'Đã đặt hàng', time: '09:30'),
      DeliveredTimelineEvent(title: 'Đã xác nhận', time: '09:32'),
      DeliveredTimelineEvent(title: 'Đang chuẩn bị', time: '09:35'),
      DeliveredTimelineEvent(title: 'Đang giao', time: '09:45'),
      DeliveredTimelineEvent(title: 'Đã giao', time: '09:51'),
    ],
  ),
];

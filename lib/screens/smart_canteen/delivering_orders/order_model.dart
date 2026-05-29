enum OrderStatus { delivering, completed }

enum PaymentMethod { cash, bankQr }

enum DeliveryStage { received, preparing, pickedUp, delivering, completed }

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

class DeliveryInfoModel {
  const DeliveryInfoModel({
    required this.shipperName,
    required this.phone,
    required this.avatarSeed,
    required this.destination,
    required this.remainingDistance,
  });

  final String shipperName;
  final String phone;
  final int avatarSeed;
  final String destination;
  final String remainingDistance;
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderedAt,
    required this.paymentMethod,
    required this.items,
    required this.delivery,
    required this.totalDeliveryTime,
    required this.remainingTime,
    this.status = OrderStatus.delivering,
    this.stage = DeliveryStage.delivering,
    this.note,
  });

  final String id;
  final String orderedAt;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final List<OrderItemModel> items;
  final DeliveryInfoModel delivery;
  final Duration totalDeliveryTime;
  final Duration remainingTime;
  final DeliveryStage stage;
  final String? note;

  int get total => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  OrderModel copyWith({
    OrderStatus? status,
    DeliveryStage? stage,
    Duration? remainingTime,
  }) {
    return OrderModel(
      id: id,
      orderedAt: orderedAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      items: items,
      delivery: delivery,
      totalDeliveryTime: totalDeliveryTime,
      remainingTime: remainingTime ?? this.remainingTime,
      stage: stage ?? this.stage,
      note: note,
    );
  }
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
    PaymentMethod.cash => 'Tiền mặt',
    PaymentMethod.bankQr => 'Chuyển khoản ngân hàng',
  };
}

const demoDeliveringOrders = <OrderModel>[
  OrderModel(
    id: 'SC260525-000156',
    orderedAt: '25/05/2026 - 10:31',
    paymentMethod: PaymentMethod.bankQr,
    totalDeliveryTime: Duration(minutes: 12),
    remainingTime: Duration(minutes: 5),
    note: 'Giao tại sảnh thư viện.',
    delivery: DeliveryInfoModel(
      shipperName: 'Minh Tuấn',
      phone: '0909 246 810',
      avatarSeed: 0,
      destination: 'Sảnh thư viện - Khu A',
      remainingDistance: '450 m',
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
  ),
  OrderModel(
    id: 'SC260525-000154',
    orderedAt: '25/05/2026 - 10:24',
    paymentMethod: PaymentMethod.bankQr,
    totalDeliveryTime: Duration(minutes: 9),
    remainingTime: Duration(minutes: 2, seconds: 15),
    delivery: DeliveryInfoModel(
      shipperName: 'Hoàng Nam',
      phone: '0912 678 345',
      avatarSeed: 1,
      destination: 'Tòa nhà B - Tầng 1',
      remainingDistance: '180 m',
    ),
    items: [
      OrderItemModel(
        name: 'Phở bò đặc biệt',
        quantity: 1,
        price: 38000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
  ),
  OrderModel(
    id: 'SC260525-000151',
    orderedAt: '25/05/2026 - 10:17',
    paymentMethod: PaymentMethod.cash,
    totalDeliveryTime: Duration(minutes: 8),
    remainingTime: Duration(seconds: 3),
    delivery: DeliveryInfoModel(
      shipperName: 'Anh Khoa',
      phone: '0988 110 220',
      avatarSeed: 2,
      destination: 'Ký túc xá C - Cổng chính',
      remainingDistance: '20 m',
    ),
    items: [
      OrderItemModel(
        name: 'Mì xào hải sản',
        quantity: 1,
        price: 35000,
        imageAsset: 'assets/images/salad.jpg',
      ),
    ],
  ),
];

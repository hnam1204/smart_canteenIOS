enum OrderStatus { preparing, readyForPickup }

enum PaymentMethod { cash, bankQr }

enum PreparationStage { received, cooking, packing, almostReady, ready }

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

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderedAt,
    required this.paymentMethod,
    required this.pickupCounter,
    required this.items,
    required this.stage,
    required this.totalPreparationTime,
    required this.remainingTime,
    this.status = OrderStatus.preparing,
    this.note,
  });

  final String id;
  final String orderedAt;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String pickupCounter;
  final List<OrderItemModel> items;
  final PreparationStage stage;
  final Duration totalPreparationTime;
  final Duration remainingTime;
  final String? note;

  int get total => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  OrderModel copyWith({
    OrderStatus? status,
    PreparationStage? stage,
    Duration? remainingTime,
  }) {
    return OrderModel(
      id: id,
      orderedAt: orderedAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      pickupCounter: pickupCounter,
      items: items,
      stage: stage ?? this.stage,
      totalPreparationTime: totalPreparationTime,
      remainingTime: remainingTime ?? this.remainingTime,
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
    PaymentMethod.cash => 'Tiền mặt tại quầy',
    PaymentMethod.bankQr => 'Chuyển khoản ngân hàng',
  };
}

String preparationStageLabel(PreparationStage stage) {
  return switch (stage) {
    PreparationStage.received => 'Đã nhận đơn',
    PreparationStage.cooking => 'Đang nấu',
    PreparationStage.packing => 'Đang đóng gói',
    PreparationStage.almostReady => 'Sắp sẵn sàng',
    PreparationStage.ready => 'Sẵn sàng nhận',
  };
}

const demoPreparingOrders = <OrderModel>[
  OrderModel(
    id: 'SC260525-000149',
    orderedAt: '25/05/2026 - 10:26',
    paymentMethod: PaymentMethod.bankQr,
    pickupCounter: 'Quầy A',
    stage: PreparationStage.cooking,
    totalPreparationTime: Duration(minutes: 15),
    remainingTime: Duration(minutes: 8),
    note: 'Thêm tương ớt riêng.',
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
    id: 'SC260525-000146',
    orderedAt: '25/05/2026 - 10:19',
    paymentMethod: PaymentMethod.bankQr,
    pickupCounter: 'Quầy B',
    stage: PreparationStage.packing,
    totalPreparationTime: Duration(minutes: 12),
    remainingTime: Duration(minutes: 2, seconds: 35),
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
  ),
  OrderModel(
    id: 'SC260525-000143',
    orderedAt: '25/05/2026 - 10:08',
    paymentMethod: PaymentMethod.cash,
    pickupCounter: 'Quầy C',
    stage: PreparationStage.almostReady,
    totalPreparationTime: Duration(minutes: 10),
    remainingTime: Duration(seconds: 3),
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

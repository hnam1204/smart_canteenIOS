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
    required this.placedAt,
    required this.readyAt,
    required this.pickupCounter,
    required this.pickupDescription,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.orderStatus,
    required this.isCancelled,
    required this.pickupEnabled,
    required this.items,
  });

  final String id;
  final String placedAt;
  final String readyAt;
  final String pickupCounter;
  final String pickupDescription;
  final String paymentStatus;
  final String paymentMethod;
  final String orderStatus;
  final bool isCancelled;
  final bool pickupEnabled;
  final List<OrderItemModel> items;

  int get total => items.fold<int>(0, (sum, item) => sum + item.total);
}

const demoPickupOrder = OrderModel(
  id: 'SC250522-000123',
  placedAt: '22/05/2026 - 09:30',
  readyAt: '09:45',
  pickupCounter: 'Quầy A',
  pickupDescription: 'Cơm gà xối mỡ',
  paymentStatus: 'paid',
  paymentMethod: 'bankQr',
  orderStatus: 'ready',
  isCancelled: false,
  pickupEnabled: true,
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
    OrderItemModel(
      name: 'Bánh flan',
      quantity: 1,
      price: 10000,
      imageAsset: 'assets/images/salad.jpg',
    ),
  ],
);

enum OrderHistoryStatus { pending, preparing, delivering, delivered, completed, cancelled }

enum OrderHistoryFilter {
  all,
  pending,
  preparing,
  delivering,
  completed,
  cancelled,
}

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

class OrderModel {
  const OrderModel({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    required this.items,
    this.readyAt,
    this.cancelledAt,
    this.pickupCounter = 'Quầy A',
    this.hasReview = false,
    this.firestoreId = '',
    this.pickupEnabled = true,
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'cash',
  });

  final String id;
  final String date;
  final String time;
  final OrderHistoryStatus status;
  final List<OrderItemModel> items;
  final String? readyAt;
  final String? cancelledAt;
  final String pickupCounter;
  final bool hasReview;
  final String firestoreId;
  final bool pickupEnabled;
  final String paymentStatus;
  final String paymentMethod;

  int get total => items.fold<int>(0, (sum, item) => sum + item.total);

  bool get canViewQr => status != OrderHistoryStatus.cancelled;
}

const demoOrderHistory = <OrderModel>[
  OrderModel(
    id: 'SC250522-000123',
    date: '22/05/2026',
    time: '09:15',
    status: OrderHistoryStatus.completed,
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
        price: 12000,
        imageAsset: 'assets/images/salad.jpg',
      ),
    ],
  ),
  OrderModel(
    id: 'SC250521-000087',
    date: '21/05/2026',
    time: '12:05',
    status: OrderHistoryStatus.preparing,
    readyAt: '12:20',
    items: [
      OrderItemModel(
        name: 'Phở bò',
        quantity: 1,
        price: 30000,
        imageAsset: 'assets/images/pho.jpg',
      ),
      OrderItemModel(
        name: 'Trà đào',
        quantity: 1,
        price: 12000,
        imageAsset: 'assets/images/chicken_rice.jpg',
      ),
    ],
  ),
  OrderModel(
    id: 'SC250520-000045',
    date: '20/05/2026',
    time: '08:40',
    status: OrderHistoryStatus.completed,
    items: [
      OrderItemModel(
        name: 'Mì xào hải sản',
        quantity: 1,
        price: 20000,
        imageAsset: 'assets/images/salad.jpg',
      ),
      OrderItemModel(
        name: 'Coca',
        quantity: 1,
        price: 10000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
  ),
  OrderModel(
    id: 'SC250519-000032',
    date: '19/05/2026',
    time: '17:30',
    status: OrderHistoryStatus.cancelled,
    cancelledAt: '19/05/2026 - 17:35',
    items: [
      OrderItemModel(
        name: 'Bánh mì thịt nướng',
        quantity: 1,
        price: 14000,
        imageAsset: 'assets/images/chicken_rice.jpg',
      ),
      OrderItemModel(
        name: 'Trà sữa',
        quantity: 1,
        price: 10000,
        imageAsset: 'assets/images/pho.jpg',
      ),
    ],
  ),
  OrderModel(
    id: 'SC250518-000019',
    date: '18/05/2026',
    time: '11:10',
    status: OrderHistoryStatus.completed,
    items: [
      OrderItemModel(
        name: 'Bún bò Huế',
        quantity: 1,
        price: 36000,
        imageAsset: 'assets/images/salad.jpg',
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
    id: 'SC250524-000141',
    date: '24/05/2026',
    time: '10:10',
    status: OrderHistoryStatus.pending,
    items: [
      OrderItemModel(
        name: 'Cơm gà xối mỡ',
        quantity: 1,
        price: 32000,
        imageAsset: 'assets/images/chicken_rice.jpg',
      ),
    ],
  ),
];

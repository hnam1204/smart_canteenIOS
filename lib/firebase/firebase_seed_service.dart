import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_config.dart';
import '../models/firestore_models.dart';
import 'firestore_service.dart';

class FirebaseSeedService {
  FirebaseSeedService({FirestoreService? service, FirebaseAuth? auth})
    : _service = service ?? FirestoreService(),
      _auth = auth ?? FirebaseAuth.instance;

  final FirestoreService _service;
  final FirebaseAuth _auth;

  Future<void> seedDevelopmentData() async {
    if (AppConfig.isProduction) return;
    await _seedPublicCollections();
    final user = _auth.currentUser;
    if (user != null) await _seedUserCollections(user);
  }

  Future<void> _seedPublicCollections() async {
    final categories = await _service.collection('categories').limit(1).get();
    final foods = await _service.collection('foods').limit(1).get();
    final vouchers = await _service.collection('vouchers').limit(1).get();
    if (categories.docs.isNotEmpty &&
        foods.docs.isNotEmpty &&
        vouchers.docs.isNotEmpty) {
      return;
    }
    final batch = _service.batch();
    if (categories.docs.isEmpty) {
      for (final item in _categories) {
        batch.set(
          _service.collection('categories').doc(item.id),
          item.toFirestore(),
        );
      }
    }
    if (foods.docs.isEmpty) {
      for (final item in _foods) {
        batch.set(
          _service.collection('foods').doc(item.id),
          item.toFirestore(),
        );
      }
    }
    if (vouchers.docs.isEmpty) {
      for (final item in _vouchers) {
        batch.set(
          _service.collection('vouchers').doc(item.id),
          item.toFirestore(),
        );
      }
    }
    await batch.commit();
  }

  Future<void> _seedUserCollections(User user) async {
    final uid = user.uid;
    final orders = await _service
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    final notifications = await _service
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    final profile = await _service.collection('users').doc(uid).get();
    final cart = await _service.collection('carts').doc(uid).get();
    final batch = _service.batch();
    if (!profile.exists) {
      final profileModel = UserModel(
        uid: uid,
        fullName: user.displayName ?? 'Nguyễn Hải Nam',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '0901 234 567',
        avatarUrl: 'https://api.dicebear.com/9.x/personas/svg?seed=$uid',
        points: 1250,
        role: 'customer',
        createdAt: DateTime.now(),
      );
      batch.set(
        _service.collection('users').doc(uid),
        profileModel.toFirestore(),
      );
    }
    if (!cart.exists) {
      batch.set(
        _service.collection('carts').doc(uid),
        CartModel(
          userId: uid,
          items: _cartItems,
          updatedAt: DateTime.now(),
        ).toFirestore(),
      );
    }
    if (orders.docs.isEmpty) {
      for (final item in _ordersFor(uid)) {
        batch.set(
          _service.collection('orders').doc(item.id),
          item.toFirestore(),
        );
      }
    }
    if (notifications.docs.isEmpty) {
      for (final item in _notificationsFor(uid)) {
        batch.set(
          _service.collection('notifications').doc(item.id),
          item.toFirestore(),
        );
      }
    }
    await batch.commit();
  }

  static final _now = DateTime(2026, 5, 26, 9, 30);
  static const _categories = [
    CategoryModel(
      id: 'rice',
      name: 'Cơm',
      icon: 'rice_bowl',
      color: '#FF6B00',
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'noodle',
      name: 'Món nước',
      icon: 'ramen_dining',
      color: '#2563EB',
      sortOrder: 2,
    ),
    CategoryModel(
      id: 'drink',
      name: 'Đồ uống',
      icon: 'local_drink',
      color: '#16A34A',
      sortOrder: 3,
    ),
    CategoryModel(
      id: 'dessert',
      name: 'Tráng miệng',
      icon: 'cake',
      color: '#7C3AED',
      sortOrder: 4,
    ),
  ];

  static final _foods = [
    FoodModel(
      id: 'chicken_rice',
      name: 'Cơm gà xối mỡ',
      description: 'Cơm trắng, gà chiên giòn, dưa leo và sốt đặc biệt',
      price: 32000,
      imageUrl: 'assets/images/chicken_rice.jpg',
      categoryId: 'rice',
      categoryName: 'Cơm',
      isAvailable: true,
      rating: 4.8,
      soldCount: 286,
      createdAt: _now,
    ),
    FoodModel(
      id: 'pho_bo',
      name: 'Phở bò',
      description: 'Phở bò tái, hành lá và rau thơm',
      price: 30000,
      imageUrl: 'assets/images/pho.jpg',
      categoryId: 'noodle',
      categoryName: 'Món nước',
      isAvailable: true,
      rating: 4.7,
      soldCount: 220,
      createdAt: _now,
    ),
    FoodModel(
      id: 'salad',
      name: 'Salad gà',
      description: 'Rau tươi, ức gà và sốt mè rang',
      price: 28000,
      imageUrl: 'assets/images/salad.jpg',
      categoryId: 'rice',
      categoryName: 'Cơm',
      isAvailable: true,
      rating: 4.6,
      soldCount: 98,
      createdAt: _now,
    ),
  ];

  static final _vouchers = [
    VoucherModel(
      id: 'fresh20',
      title: 'Ưu đãi bữa trưa - giảm 20%',
      code: 'FRESH20',
      description: 'Giảm 20% cho đơn ăn trưa từ 60.000đ',
      discountType: 'percent',
      discountValue: 20,
      minOrderAmount: 60000,
      maxDiscount: 30000,
      usageLimit: 100,
      usedCount: 0,
      claimLimit: 100,
      claimedCount: 0,
      userLimit: 1,
      exchangePoints: 50,
      isExchangeable: true,
      isClaimable: true,
      isActive: true,
      expiredAt: DateTime(2026, 6, 30),
    ),
    VoucherModel(
      id: 'freeship',
      title: 'Freeship trong campus',
      code: 'FREESHIP',
      description: 'Miễn phí giao hàng cho đơn từ 45.000đ',
      discountType: 'amount',
      discountValue: 15000,
      minOrderAmount: 45000,
      maxDiscount: 15000,
      usageLimit: 100,
      usedCount: 0,
      claimLimit: 100,
      claimedCount: 0,
      userLimit: 1,
      exchangePoints: 30,
      isExchangeable: true,
      isClaimable: true,
      isActive: true,
      expiredAt: DateTime(2026, 7, 15),
    ),
  ];

  static const _cartItems = [
    CartItemModel(
      foodId: 'chicken_rice',
      name: 'Cơm gà xối mỡ',
      imageUrl: 'assets/images/chicken_rice.jpg',
      basePrice: 32000,
      quantity: 1,
    ),
    CartItemModel(
      foodId: 'pho_bo',
      name: 'Phở bò',
      imageUrl: 'assets/images/pho.jpg',
      basePrice: 30000,
      quantity: 1,
    ),
  ];

  static List<OrderModel> _ordersFor(String uid) => [
    OrderModel(
      id: 'order_sc250522_000123_$uid',
      userId: uid,
      orderCode: 'SC250522-000123',
      items: const [
        OrderItemModel(
          foodId: 'chicken_rice',
          name: 'Cơm gà xối mỡ',
          imageUrl: 'assets/images/chicken_rice.jpg',
          basePrice: 32000,
          quantity: 1,
        ),
        OrderItemModel(
          foodId: 'pho_bo',
          name: 'Trà tắc',
          imageUrl: 'assets/images/pho.jpg',
          basePrice: 12000,
          quantity: 1,
        ),
      ],
      totalAmount: 44000,
      paymentMethod: 'bankQr',
      paymentStatus: 'paid',
      orderStatus: 'completed',
      pickupCounter: 'Quầy A',
      note: '',
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now,
      pickupEnabled: true,
      qrCodeData: 'SC250522-000123',
    ),
  ];

  static List<NotificationModel> _notificationsFor(String uid) => [
    NotificationModel(
      id: 'notification_offer_$uid',
      userId: uid,
      title: 'Ưu đãi đặc biệt dành cho bạn!',
      message: 'Giảm 20% cho đơn hàng từ 40.000đ',
      type: 'promotion',
      isRead: false,
      createdAt: _now,
    ),
    NotificationModel(
      id: 'notification_order_$uid',
      userId: uid,
      title: 'Đơn hàng đã hoàn thành',
      message: 'Đơn hàng SC250522-000123 của bạn đã hoàn thành.',
      type: 'orderCompleted',
      isRead: false,
      createdAt: _now.subtract(const Duration(hours: 2)),
    ),
  ];
}

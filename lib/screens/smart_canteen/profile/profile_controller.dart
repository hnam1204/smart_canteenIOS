import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/cart_repository.dart';
import '../../../repositories/notification_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/user_repository.dart';
import 'user_model.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    UserRepository? userRepository,
    OrderRepository? orderRepository,
    CartRepository? cartRepository,
    NotificationRepository? notificationRepository,
  }) : _userRepository = userRepository,
       _orderRepository = orderRepository,
       _cartRepository = cartRepository,
       _notificationRepository = notificationRepository;

  UserRepository? _userRepository;
  OrderRepository? _orderRepository;
  CartRepository? _cartRepository;
  NotificationRepository? _notificationRepository;

  UserProfile? _profile;
  store.UserModel? _user;
  List<store.OrderModel> _orders = const [];
  store.CartModel? _cart;
  List<store.NotificationModel> _notifications = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _disposed = false;
  Timer? _loadTimer;
  Timer? _refreshTimer;
  StreamSubscription<store.UserModel?>? _userSubscription;
  StreamSubscription<List<store.OrderModel>>? _orderSubscription;
  StreamSubscription<store.CartModel?>? _cartSubscription;
  StreamSubscription<List<store.NotificationModel>>? _notificationSubscription;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  bool get refreshing => _refreshing;

  void load() {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _listenToFirestore(FirebaseAuth.instance.currentUser!.uid);
      return;
    }
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 430), () {
      if (_disposed) return;
      _profile = demoUserProfile;
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _refreshing = true;
      _notify();
      _listenToFirestore(FirebaseAuth.instance.currentUser!.uid);
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    _notify();
    final completer = Completer<void>();
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 650), () {
      _refreshing = false;
      _profile ??= demoUserProfile;
      _notify();
      completer.complete();
    });
    return completer.future;
  }

  void updateAvatar() {
    final current = _profile;
    if (current == null) return;
    _profile = current.copyWith(avatarVariant: (current.avatarVariant + 1) % 3);
    _notify();
  }

  void _listenToFirestore(String uid) {
    _userRepository ??= UserRepository();
    _orderRepository ??= OrderRepository();
    _cartRepository ??= CartRepository();
    _notificationRepository ??= NotificationRepository();
    _userSubscription?.cancel();
    _orderSubscription?.cancel();
    _cartSubscription?.cancel();
    _notificationSubscription?.cancel();
    _userSubscription = _userRepository!.watchUser(uid).listen((user) {
      _user = user;
      _rebuildProfile(uid);
    }, onError: (_) => _finishLoading());
    _orderSubscription = _orderRepository!.watchOrders(uid).listen((orders) {
      _orders = orders;
      _rebuildProfile(uid);
    }, onError: (_) => _finishLoading());
    _cartSubscription = _cartRepository!.watchCart(uid).listen((cart) {
      _cart = cart;
      _rebuildProfile(uid);
    }, onError: (_) => _finishLoading());
    _notificationSubscription = _notificationRepository!
        .watchNotifications(uid)
        .listen((notifications) {
          _notifications = notifications;
          _rebuildProfile(uid);
        }, onError: (_) => _finishLoading());
  }

  void _rebuildProfile(String uid) {
    final user = _user;
    if (user == null) {
      _finishLoading();
      return;
    }
    int countWhere(bool Function(store.OrderModel order) matches) =>
        _orders.where(matches).length;
    _profile = UserProfile(
      id: uid,
      fullName: user.fullName,
      phone: user.phone,
      email: user.email,
      points: user.points,
      avatarUrl: user.avatarUrl,
      cartCount:
          _cart?.items.fold<int>(0, (value, item) => value + item.quantity) ??
          0,
      unreadNotifications: _notifications
          .where((notification) => !notification.isRead)
          .length,
      avatarVariant: _profile?.avatarVariant ?? 0,
      orderStatuses: [
        OrderStatusSummary(
          kind: OrderStatusKind.all,
          label: 'Tất cả đơn',
          count: _orders.length,
        ),
        OrderStatusSummary(
          kind: OrderStatusKind.pending,
          label: 'Chờ xác nhận',
          count: countWhere((order) => order.orderStatus == 'pending'),
        ),
        OrderStatusSummary(
          kind: OrderStatusKind.preparing,
          label: 'Đang chuẩn bị',
          count: countWhere((order) => order.orderStatus == 'preparing'),
        ),
        OrderStatusSummary(
          kind: OrderStatusKind.delivering,
          label: 'Đang giao',
          count: countWhere((order) => order.orderStatus == 'delivering'),
        ),
        OrderStatusSummary(
          kind: OrderStatusKind.completed,
          label: 'Đã hoàn thành',
          count: countWhere(
            (order) =>
                order.orderStatus == 'completed' ||
                order.orderStatus == 'delivered',
          ),
        ),
        OrderStatusSummary(
          kind: OrderStatusKind.cancelled,
          label: 'Đã hủy',
          count: countWhere((order) => order.orderStatus == 'cancelled'),
        ),
      ],
      menuOptions: demoUserProfile.menuOptions,
    );
    _finishLoading();
  }

  void _finishLoading() {
    _loading = false;
    _refreshing = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadTimer?.cancel();
    _refreshTimer?.cancel();
    unawaited(_userSubscription?.cancel());
    unawaited(_orderSubscription?.cancel());
    unawaited(_cartSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }
}

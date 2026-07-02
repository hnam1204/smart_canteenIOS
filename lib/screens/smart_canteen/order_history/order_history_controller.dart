import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';


import '../../../core/utils/safe_change_notifier.dart';
import '../../../models/firestore_models.dart' as firestore;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

class OrderHistoryController extends SafeChangeNotifier {
  OrderHistoryController({OrderRepository? repository})
    : _repository = repository;

  OrderRepository? _repository;
  OrderHistoryFilter _filter = OrderHistoryFilter.all;
  List<OrderModel> _orders = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _disposed = false;
  StreamSubscription<List<firestore.OrderModel>>? _subscription;

  OrderHistoryFilter get filter => _filter;
  bool get loading => _loading;
  bool get refreshing => _refreshing;

  List<OrderModel> get visibleOrders {
    if (_filter == OrderHistoryFilter.all) return _orders;
    return _orders
        .where((order) => _matches(order.status, _filter))
        .toList(growable: false);
  }

  Future<void> load() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _repository ??= OrderRepository();
      await _subscription?.cancel();
      _subscription = _repository!
          .watchOrders(FirebaseAuth.instance.currentUser!.uid)
          .listen(
            (orders) {
              if (_disposed) return;
              _orders = orders.map(_fromFirestore).toList(growable: false);
              _loading = false;
              _refreshing = false;
              notifyListeners();
            },
            onError: (_) {
              if (_disposed) return;
              _loading = false;
              _refreshing = false;
              notifyListeners();
            },
          );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 430));
    if (_disposed) return;
    _orders = List<OrderModel>.of(demoOrderHistory);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _refreshing = true;
      notifyListeners();
      await load();
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (_disposed) return;
    _orders = List<OrderModel>.of(demoOrderHistory);
    _refreshing = false;
    notifyListeners();
  }

  void setFilter(OrderHistoryFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  bool _matches(OrderHistoryStatus status, OrderHistoryFilter filter) {
    switch (filter) {
      case OrderHistoryFilter.all:
        return true;
      case OrderHistoryFilter.pending:
        return status == OrderHistoryStatus.pending;
      case OrderHistoryFilter.preparing:
        return status == OrderHistoryStatus.preparing;
      case OrderHistoryFilter.delivering:
        return status == OrderHistoryStatus.delivering;
      case OrderHistoryFilter.completed:
        return status == OrderHistoryStatus.delivered ||
            status == OrderHistoryStatus.completed;
      case OrderHistoryFilter.cancelled:
        return status == OrderHistoryStatus.cancelled;
    }
  }

  OrderModel _fromFirestore(firestore.OrderModel order) {
    final created = order.createdAt;
    String two(int value) => value.toString().padLeft(2, '0');
    final status = switch (order.orderStatus.trim()) {
      'pending' => OrderHistoryStatus.pending,
      'preparing' => OrderHistoryStatus.preparing,
      'ready' || 'delivering' || 'readyForPickup' => OrderHistoryStatus.delivering,
      'delivered' => OrderHistoryStatus.delivered,
      'completed' || 'done' || 'success' || 'finished' || 'complete' => OrderHistoryStatus.completed,
      'cancelled' => OrderHistoryStatus.cancelled,
      _ => OrderHistoryStatus.completed,
    };
    return OrderModel(
      id: order.orderCode.isEmpty ? order.id : order.orderCode,
      date: '${two(created.day)}/${two(created.month)}/${created.year}',
      time: '${two(created.hour)}:${two(created.minute)}',
      status: status,
      pickupCounter: order.pickupCounter,
      readyAt: status == OrderHistoryStatus.preparing ? 'Đang cập nhật' : null,
      hasReview: order.hasReview,
      firestoreId: order.id,
      pickupEnabled: order.pickupEnabled,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
      items: order.items
          .map(
            (item) => OrderItemModel(
              name: item.name,
              quantity: item.quantity,
              price: item.total ~/ item.quantity,
              imageAsset: item.imageUrl,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

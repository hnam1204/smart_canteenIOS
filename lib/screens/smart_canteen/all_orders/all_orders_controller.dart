import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

class AllOrdersController extends ChangeNotifier {
  AllOrdersController({
    OrderFilter initialFilter = OrderFilter.all,
    OrderRepository? repository,
    List<OrderModel>? offlineOrders,
  }) : _filter = initialFilter,
       _repository = repository,
       _offlineOrders = offlineOrders;

  OrderRepository? _repository;
  final List<OrderModel>? _offlineOrders;
  List<OrderModel> _orders = const [];
  OrderFilter _filter;
  String _query = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _disposed = false;
  StreamSubscription<List<store.OrderModel>>? _subscription;

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  OrderFilter get filter => _filter;
  String get query => _query;
  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> get visibleOrders {
    final keyword = _query.trim().toLowerCase();
    return _orders
        .where((order) {
          final filterMatches =
              _filter == OrderFilter.all ||
              _matchesFilter(order.status, _filter);
          if (!filterMatches) return false;
          if (keyword.isEmpty) return true;
          final haystack = [
            order.id,
            order.pickupCounter,
            order.paymentMethod,
            orderStatusLabel(order.status),
            paymentStatusLabel(order.paymentStatus),
            ...order.items.map((item) => item.name),
          ].join(' ').toLowerCase();
          return haystack.contains(keyword);
        })
        .toList(growable: false);
  }

  int get totalOrders => _orders.length;
  int get totalSpent => _orders
      .where((order) => order.status != OrderStatus.cancelled)
      .fold<int>(0, (total, order) => total + order.total);
  int get processingOrders => _orders
      .where(
        (order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.delivering,
      )
      .length;

  int countFor(OrderFilter filter) {
    if (filter == OrderFilter.all) return _orders.length;
    return _orders
        .where((order) => _matchesFilter(order.status, filter))
        .length;
  }

  Future<void> load() async {
    _loading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user == null) {
      await _subscription?.cancel();
      if (_disposed) return;
      _orders = List<OrderModel>.of(_offlineOrders ?? const []);
      _loading = false;
      _refreshing = false;
      notifyListeners();
      return;
    }

    _repository ??= OrderRepository();
    await _subscription?.cancel();
    _subscription = _repository!
        .watchOrders(user.uid)
        .listen(
          (orders) {
            if (_disposed) return;
            final sorted = [...orders]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _orders = sorted.map(_fromFirestore).toList(growable: false);
            _loading = false;
            _refreshing = false;
            _hasError = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (_disposed) return;
            _orders = List<OrderModel>.of(_offlineOrders ?? const []);
            _hasError = true;
            _errorMessage = _messageForError(error);
            _loading = false;
            _refreshing = false;
            notifyListeners();
          },
        );
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    await load();
  }

  void setFilter(OrderFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void updateSearch(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearSearch() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  bool cancelOrder(String id) {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      return false;
    }
    _replaceStatus(id, OrderStatus.cancelled, PaymentStatus.refunded);
    return true;
  }

  void _replaceStatus(
    String id,
    OrderStatus status,
    PaymentStatus paymentStatus,
  ) {
    _orders = [
      for (final order in _orders)
        if (order.id == id)
          order.copyWith(status: status, paymentStatus: paymentStatus)
        else
          order,
    ];
    notifyListeners();
  }

  void retry() => load();

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  OrderModel _fromFirestore(store.OrderModel order) {
    String two(int value) => value.toString().padLeft(2, '0');
    final created = order.createdAt;
    return OrderModel(
      id: order.orderCode.isEmpty ? order.id : order.orderCode,
      orderedAt:
          '${two(created.day)}/${two(created.month)}/${created.year} - ${two(created.hour)}:${two(created.minute)}',
      status: _parseOrderStatus(order.orderStatus),
      paymentStatus: _parsePaymentStatus(order.paymentStatus),
      pickupCounter: order.pickupCounter.isEmpty
          ? 'Quầy nhận món'
          : order.pickupCounter,
      note: order.note.isEmpty ? null : order.note,
      paymentMethod: order.paymentMethod,
      totalAmount: order.totalAmount,
      pickupEnabled: order.pickupEnabled,
      hasReview: order.hasReview,
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
      timeline: [
        OrderTimelineEvent(
          title: 'Đã đặt hàng',
          time: '${two(created.hour)}:${two(created.minute)}',
        ),
      ],
    );
  }

  bool _matchesFilter(OrderStatus status, OrderFilter filter) {
    return switch (filter) {
      OrderFilter.all => true,
      OrderFilter.pending => status == OrderStatus.pending,
      OrderFilter.preparing => status == OrderStatus.preparing,
      OrderFilter.delivering => status == OrderStatus.delivering,
      OrderFilter.completed =>
        status == OrderStatus.delivered || status == OrderStatus.completed,
      OrderFilter.cancelled => status == OrderStatus.cancelled,
    };
  }

  OrderStatus _parseOrderStatus(String value) {
    return switch (value.trim()) {
      'pending' => OrderStatus.pending,
      'preparing' => OrderStatus.preparing,
      'delivering' => OrderStatus.delivering,
      'delivered' => OrderStatus.delivered,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      'ready' || 'readyForPickup' => OrderStatus.preparing,
      _ => OrderStatus.pending,
    };
  }

  PaymentStatus _parsePaymentStatus(String value) {
    return switch (value.trim()) {
      'pending' => PaymentStatus.pending,
      'unpaid' || 'cashOnPickup' => PaymentStatus.unpaid,
      'paid' => PaymentStatus.paid,
      'failed' => PaymentStatus.failed,
      'expired' => PaymentStatus.expired,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.pending,
    };
  }

  String _messageForError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        debugPrint('Orders permission denied: ${error.message ?? error}');
        return 'Bạn chưa có quyền đọc đơn hàng. Vui lòng đăng nhập lại.';
      }
      if (error.code == 'failed-precondition') {
        debugPrint(
          'Orders query needs Firestore index: ${error.message ?? error}',
        );
        return 'Cần tạo Firestore index cho orders.';
      }
      debugPrint(
        'Orders Firestore error (${error.code}): ${error.message ?? error}',
      );
      return error.message ?? 'Không thể tải đơn hàng.';
    }
    debugPrint('Orders load error: $error');
    return 'Không thể tải đơn hàng.';
  }
}

String orderStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'Chờ xác nhận',
    OrderStatus.preparing => 'Đang chuẩn bị',
    OrderStatus.delivering => 'Đang giao',
    OrderStatus.delivered => 'Đã giao',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
  };
}

String paymentStatusLabel(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.pending => 'Chờ xác nhận chuyển khoản',
    PaymentStatus.unpaid => 'Thanh toán tại quầy',
    PaymentStatus.paid => 'Đã thanh toán',
    PaymentStatus.failed => 'Thanh toán thất bại',
    PaymentStatus.expired => 'Đã hết hạn',
    PaymentStatus.refunded => 'Đã hoàn tiền',
  };
}

String formatOrderCurrency(int value) {
  final raw = value.toString();
  return '${raw.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/safe_change_notifier.dart';
import '../../../models/firestore_models.dart' as store;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

enum WaitingFilter { all, normal, delayed }

class PendingOrdersController extends SafeChangeNotifier {
  PendingOrdersController({OrderRepository? repository})
    : _repository = repository,
      _orders = <OrderModel>[];

  OrderRepository? _repository;
  final List<OrderModel> _orders;
  final Map<String, Duration> _waitingTimes = {};
  Timer? _waitingTimer;
  StreamSubscription<List<store.OrderModel>>? _subscription;
  bool loading = true;
  bool refreshing = false;
  bool hasError = false;
  String errorMessage = '';
  String _query = '';
  WaitingFilter filter = WaitingFilter.all;

  List<OrderModel> get visibleOrders {
    return _orders
        .where((order) {
          final matchesFilter = switch (filter) {
            WaitingFilter.all => true,
            WaitingFilter.normal =>
              waitingFor(order) < const Duration(minutes: 10),
            WaitingFilter.delayed =>
              waitingFor(order) >= const Duration(minutes: 10),
          };
          final query = _query.toLowerCase();
          final matchesSearch =
              query.isEmpty ||
              order.id.toLowerCase().contains(query) ||
              order.items.any(
                (item) => item.name.toLowerCase().contains(query),
              );
          return matchesFilter && matchesSearch;
        })
        .toList(growable: false);
  }

  int countFor(WaitingFilter value) {
    return _orders.where((order) {
      return switch (value) {
        WaitingFilter.all => true,
        WaitingFilter.normal => waitingFor(order) < const Duration(minutes: 10),
        WaitingFilter.delayed =>
          waitingFor(order) >= const Duration(minutes: 10),
      };
    }).length;
  }

  Duration waitingFor(OrderModel order) =>
      _waitingTimes[order.id] ?? order.waitingTime;

  Future<void> load() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _repository ??= OrderRepository();
      _orders.clear();
      await _subscription?.cancel();
      _subscription = _repository!
          .watchOrders(FirebaseAuth.instance.currentUser!.uid)
          .listen(
            (orders) {
              _orders
                ..clear()
                ..addAll(
                  orders
                      .where(
                        (order) =>
                            _normalizeStatus(order.orderStatus) == 'pending',
                      )
                      .map(_fromFirestore),
                );
              loading = false;
              refreshing = false;
              hasError = false;
              errorMessage = '';
              _startTimer();
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint(
                'PendingOrdersController load failed: $error\n$stackTrace',
              );
              loading = false;
              refreshing = false;
              hasError = true;
              errorMessage = error.toString();
              notifyListeners();
            },
          );
      return;
    }
    loading = false;
    refreshing = false;
    hasError = false;
    errorMessage = '';
    _startTimer();
    notifyListeners();
  }

  Future<void> refresh() async {
    refreshing = true;
    notifyListeners();
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      await load();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    hasError = false;
    errorMessage = '';
    refreshing = false;
    notifyListeners();
  }

  void retry() {
    hasError = false;
    errorMessage = '';
    loading = true;
    notifyListeners();
    load();
  }

  void updateSearch(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    notifyListeners();
  }

  void setFilter(WaitingFilter value) {
    filter = value;
    notifyListeners();
  }

  bool cancelOrder(String id) {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      return false;
    }
    _orders.removeWhere((order) => order.id == id);
    _waitingTimes.remove(id);
    notifyListeners();
    return true;
  }

  OrderModel _fromFirestore(store.OrderModel order) {
    final elapsed = DateTime.now().difference(order.createdAt);
    return OrderModel(
      id: order.id,
      orderedAt: _dateTime(order.createdAt),
      waitingTime: elapsed.isNegative ? Duration.zero : elapsed,
      paymentMethod: order.paymentMethod == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.bankQr,
      pickupCounter: order.pickupCounter,
      note: order.note.isEmpty ? null : order.note,
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
        OrderTimelineEvent(title: 'Đã đặt hàng', time: _time(order.createdAt)),
      ],
    );
  }

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${_time(date)}';

  void _startTimer() {
    _waitingTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      for (final order in _orders) {
        _waitingTimes[order.id] =
            waitingFor(order) + const Duration(seconds: 1);
      }
      notifyListeners();
    });
  }

  String _normalizeStatus(String status) {
    return switch (status.trim()) {
      'pending' => 'pending',
      'preparing' => 'preparing',
      'delivering' => 'delivering',
      'delivered' => 'delivered',
      'completed' => 'completed',
      'cancelled' => 'cancelled',
      _ => status.trim(),
    };
  }

  @override
  void dispose() {
    _waitingTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

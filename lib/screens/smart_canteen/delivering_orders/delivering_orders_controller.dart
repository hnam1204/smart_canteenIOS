import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

enum DeliveryFilter { all, nearby, completed }

class DeliveringOrdersController extends ChangeNotifier {
  DeliveringOrdersController({OrderRepository? repository})
    : _repository = repository,
      _orders = List.of(demoDeliveringOrders);

  OrderRepository? _repository;
  final List<OrderModel> _orders;
  Timer? _timer;
  StreamSubscription<List<store.OrderModel>>? _subscription;
  String _query = '';
  DeliveryFilter filter = DeliveryFilter.all;
  bool loading = true;
  bool refreshing = false;
  bool hasError = false;

  List<OrderModel> get visibleOrders {
    final query = _query.toLowerCase();
    return _orders
        .where((order) {
          final filterMatch = switch (filter) {
            DeliveryFilter.all => true,
            DeliveryFilter.nearby =>
              order.status == OrderStatus.delivering &&
                  order.remainingTime <= const Duration(minutes: 3),
            DeliveryFilter.completed => order.status == OrderStatus.completed,
          };
          final searchMatch =
              query.isEmpty ||
              order.id.toLowerCase().contains(query) ||
              order.delivery.shipperName.toLowerCase().contains(query) ||
              order.items.any(
                (item) => item.name.toLowerCase().contains(query),
              );
          return filterMatch && searchMatch;
        })
        .toList(growable: false);
  }

  int countFor(DeliveryFilter value) {
    return _orders.where((order) {
      return switch (value) {
        DeliveryFilter.all => true,
        DeliveryFilter.nearby =>
          order.status == OrderStatus.delivering &&
              order.remainingTime <= const Duration(minutes: 3),
        DeliveryFilter.completed => order.status == OrderStatus.completed,
      };
    }).length;
  }

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
                            order.orderStatus == 'delivering' ||
                            order.orderStatus == 'delivered',
                      )
                      .map(_fromFirestore),
                );
              loading = false;
              refreshing = false;
              _startTimer();
              notifyListeners();
            },
            onError: (_) {
              loading = false;
              refreshing = false;
              hasError = true;
              notifyListeners();
            },
          );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!hasListeners) return;
    loading = false;
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
    if (!hasListeners) return;
    refreshing = false;
    hasError = false;
    notifyListeners();
  }

  void retry() {
    loading = true;
    hasError = false;
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

  void setFilter(DeliveryFilter value) {
    filter = value;
    notifyListeners();
  }

  OrderModel _fromFirestore(store.OrderModel order) {
    final delivered = order.orderStatus == 'delivered';
    return OrderModel(
      id: order.id,
      orderedAt: _dateTime(order.createdAt),
      status: delivered ? OrderStatus.completed : OrderStatus.delivering,
      paymentMethod: order.paymentMethod == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.bankQr,
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
      delivery: DeliveryInfoModel(
        shipperName: 'Nhân viên Smart Canteen',
        phone: '1900 0000',
        avatarSeed: 0,
        destination: order.pickupCounter,
        remainingDistance: delivered ? '0 m' : '350 m',
      ),
      totalDeliveryTime: const Duration(minutes: 10),
      remainingTime: delivered ? Duration.zero : const Duration(minutes: 5),
      stage: delivered ? DeliveryStage.completed : DeliveryStage.delivering,
      note: order.note.isEmpty ? null : order.note,
    );
  }

  String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      var changed = false;
      for (var index = 0; index < _orders.length; index++) {
        final order = _orders[index];
        if (order.status == OrderStatus.completed) continue;
        final remaining = order.remainingTime - const Duration(seconds: 1);
        if (remaining <= Duration.zero) {
          _orders[index] = order.copyWith(
            status: OrderStatus.completed,
            stage: DeliveryStage.completed,
            remainingTime: Duration.zero,
          );
        } else {
          _orders[index] = order.copyWith(remainingTime: remaining);
        }
        changed = true;
      }
      if (changed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

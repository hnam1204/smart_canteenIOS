import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

enum DeliveredFilter { all, awaitingReview, reviewed }

class DeliveredOrdersController extends ChangeNotifier {
  DeliveredOrdersController({OrderRepository? repository})
    : _repository = repository,
      _orders = List.of(demoDeliveredOrders);

  OrderRepository? _repository;
  final List<OrderModel> _orders;
  StreamSubscription<List<store.OrderModel>>? _subscription;
  String _query = '';
  DeliveredFilter filter = DeliveredFilter.all;
  bool loading = true;
  bool refreshing = false;
  bool hasError = false;

  List<OrderModel> get visibleOrders {
    final query = _query.toLowerCase();
    return _orders
        .where((order) {
          final filterMatch = switch (filter) {
            DeliveredFilter.all => true,
            DeliveredFilter.awaitingReview => !order.reviewed,
            DeliveredFilter.reviewed => order.reviewed,
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

  int get totalDelivered => _orders.length;
  int get totalSpent => _orders.fold(0, (sum, order) => sum + order.total);
  int get awaitingReview => _orders.where((order) => !order.reviewed).length;
  int get rewardPoints =>
      _orders.fold(0, (sum, order) => sum + order.rewardPoints);

  int countFor(DeliveredFilter value) {
    return _orders.where((order) {
      return switch (value) {
        DeliveredFilter.all => true,
        DeliveredFilter.awaitingReview => !order.reviewed,
        DeliveredFilter.reviewed => order.reviewed,
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
                            order.orderStatus == 'completed' ||
                            order.orderStatus == 'delivered',
                      )
                      .map(_fromFirestore),
                );
              loading = false;
              refreshing = false;
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
    hasError = false;
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

  void setFilter(DeliveredFilter value) {
    filter = value;
    notifyListeners();
  }

  OrderModel _fromFirestore(store.OrderModel order) {
    final paid = order.updatedAt;
    return OrderModel(
      id: order.id,
      orderedAt: _dateTime(order.createdAt),
      deliveredAt: _dateTime(paid),
      paymentMethod: order.paymentMethod == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.bankQr,
      reviewed: order.hasReview,
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
        destination: order.pickupCounter,
        avatarSeed: 0,
      ),
      timeline: [
        DeliveredTimelineEvent(
          title: 'Đã đặt hàng',
          time: _time(order.createdAt),
        ),
        DeliveredTimelineEvent(title: 'Đã giao', time: _time(paid)),
      ],
      invoice: InvoiceModel(
        id: 'INV-${order.orderCode}',
        paidAt: _dateTime(paid),
        discount: 0,
      ),
      rewardPoints: order.totalAmount ~/ 1000,
      note: order.note.isEmpty ? null : order.note,
    );
  }

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${_time(date)}';

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

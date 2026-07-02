import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';


import '../../../core/utils/safe_change_notifier.dart';
import '../../../models/firestore_models.dart' as store;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

enum PreparingFilter { all, cooking, packing, almostReady, ready }

class PreparingOrdersController extends SafeChangeNotifier {
  PreparingOrdersController({OrderRepository? repository})
    : _repository = repository,
      _orders = List.of(demoPreparingOrders);

  OrderRepository? _repository;
  final List<OrderModel> _orders;
  Timer? _countdownTimer;
  StreamSubscription<List<store.OrderModel>>? _subscription;
  String _query = '';
  PreparingFilter filter = PreparingFilter.all;
  bool loading = true;
  bool refreshing = false;
  bool hasError = false;

  List<OrderModel> get visibleOrders {
    final query = _query.toLowerCase();
    return _orders
        .where((order) {
          final filterMatch = switch (filter) {
            PreparingFilter.all => true,
            PreparingFilter.cooking => order.stage == PreparationStage.cooking,
            PreparingFilter.packing => order.stage == PreparationStage.packing,
            PreparingFilter.almostReady =>
              order.stage == PreparationStage.almostReady,
            PreparingFilter.ready => order.status == OrderStatus.readyForPickup,
          };
          final searchMatch =
              query.isEmpty ||
              order.id.toLowerCase().contains(query) ||
              order.items.any(
                (item) => item.name.toLowerCase().contains(query),
              );
          return filterMatch && searchMatch;
        })
        .toList(growable: false);
  }

  int countFor(PreparingFilter value) {
    return _orders.where((order) {
      return switch (value) {
        PreparingFilter.all => true,
        PreparingFilter.cooking => order.stage == PreparationStage.cooking,
        PreparingFilter.packing => order.stage == PreparationStage.packing,
        PreparingFilter.almostReady =>
          order.stage == PreparationStage.almostReady,
        PreparingFilter.ready => order.status == OrderStatus.readyForPickup,
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
                            order.orderStatus == 'preparing' ||
                            order.orderStatus == 'readyForPickup',
                      )
                      .map(_fromFirestore),
                );
              loading = false;
              refreshing = false;
              _startCountdown();
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
    _startCountdown();
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

  void setFilter(PreparingFilter value) {
    filter = value;
    notifyListeners();
  }

  OrderModel _fromFirestore(store.OrderModel order) {
    final ready = order.orderStatus == 'readyForPickup';
    return OrderModel(
      id: order.id,
      orderedAt: _dateTime(order.createdAt),
      status: ready ? OrderStatus.readyForPickup : OrderStatus.preparing,
      paymentMethod: order.paymentMethod == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.bankQr,
      pickupCounter: order.pickupCounter,
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
      stage: ready ? PreparationStage.ready : PreparationStage.cooking,
      totalPreparationTime: const Duration(minutes: 15),
      remainingTime: ready ? Duration.zero : const Duration(minutes: 8),
      note: order.note.isEmpty ? null : order.note,
    );
  }

  String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  void _startCountdown() {
    _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      var changed = false;
      for (var index = 0; index < _orders.length; index++) {
        final order = _orders[index];
        if (order.status == OrderStatus.readyForPickup) continue;
        final remaining = order.remainingTime - const Duration(seconds: 1);
        if (remaining <= Duration.zero) {
          _orders[index] = order.copyWith(
            status: OrderStatus.readyForPickup,
            stage: PreparationStage.ready,
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
    _countdownTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

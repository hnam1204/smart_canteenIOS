import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/firestore_models.dart' as store;
import '../../../repositories/order_repository.dart';
import 'order_model.dart';

class QRPickupController extends ChangeNotifier {
  QRPickupController({
    required this.orderId,
    this.previewOrder,
    OrderRepository? repository,
  }) : _repository = repository;

  static const int _maxRetries = 5;
  static const int _retryDelaySeconds = 1;

  final String orderId;
  final OrderModel? previewOrder;
  OrderRepository? _repository;
  StreamSubscription<store.OrderModel?>? _subscription;
  Timer? _retryTimer;
  OrderModel? _order;
  String _qrData = '';
  bool _loading = true;
  bool _disposed = false;
  bool _isRetrying = false;
  int _retryCount = 0;
  String? _error;

  bool get loading => _loading;
  bool get isRetrying => _isRetrying;
  int get retryCount => _retryCount;
  String? get error => _error;
  OrderModel? get order => _order;
  String get qrData => _qrData;
  bool get canDisplayQr =>
      _error == null &&
      _order != null &&
      _order!.pickupEnabled &&
      !_order!.isCancelled &&
      _qrData.isNotEmpty;
  bool get reachedRetryLimit => _retryCount >= _maxRetries;

  Future<void> load() async {
    _retryTimer?.cancel();
    debugPrint('QRPickup received orderId: $orderId');
    debugPrint('QRPickup.load: retryCount=$_retryCount');

    if (orderId.trim().isEmpty) {
      _fail('Thiếu mã đơn hàng');
      return;
    }
    if (Firebase.apps.isEmpty) {
      final preview = previewOrder;
      if (preview == null) {
        _fail('Không thể xác minh đơn hàng để hiển thị mã QR.');
        return;
      }
      _order = preview;
      _qrData = 'preview:${preview.id}';
      _loading = false;
      notifyListeners();
      return;
    }

    // If we have a previewOrder and haven't loaded real data yet,
    // show it immediately so the user never sees a blank/loading screen.
    if (previewOrder != null && _order == null) {
      _order = previewOrder;
      _qrData = previewOrder!.id;
      _loading = false;
      _isRetrying = false;
      _error = null;
      notifyListeners();
    } else if (_retryCount == 0) {
      _loading = true;
      _isRetrying = false;
      notifyListeners();
    } else if (_retryCount > 0) {
      _isRetrying = true;
      notifyListeners();
    }

    _repository ??= OrderRepository();
    await _subscription?.cancel();

    final stream = await _resolveOrderStream(orderId.trim());
    _subscription = stream.listen(
      (order) {
        if (_disposed) return;

        debugPrint('QRPickup.watchOrder: order=$order, exists=${order != null}');

        if (order == null) {
          // If we already have preview data showing, don't trigger retrying UI
          if (_order != null) return;
          _handleOrderNotFound();
          return;
        }

        if (!order.pickupEnabled) {
          _fail('Đơn hàng chưa mở tính năng nhận món.');
          return;
        }
        if (order.orderStatus == 'cancelled') {
          _order = _fromFirestore(order);
          _qrData = '';
          _error = null;
          _loading = false;
          _isRetrying = false;
          _retryCount = 0;
          notifyListeners();
          return;
        }
        final token = order.qrCodeData.isNotEmpty
            ? order.qrCodeData
            : order.pickupToken;
        if (token.isEmpty) {
          // Don't fail if we have preview data — Firestore token may arrive soon
          if (_order != null) return;
          _fail('Mã nhận món chưa được hệ thống phát hành.');
          return;
        }

        debugPrint('QRPickup.success: orderCode=${order.orderCode}, status=${order.orderStatus}');

        _order = _fromFirestore(order);
        _qrData = token;
        _error = null;
        _loading = false;
        _isRetrying = false;
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('QRPickup.streamError: $error');
        _handleLoadError(error);
      },
    );
  }

  void _handleOrderNotFound() {
    if (_disposed) return;

    if (_retryCount < _maxRetries) {
      _retryCount++;
      _isRetrying = true;
      _loading = false;
      _error = null;
      notifyListeners();

      debugPrint('QRPickup.retry: attempt $_retryCount/$_maxRetries');

      _retryTimer = Timer(
        const Duration(seconds: _retryDelaySeconds),
        () {
          if (!_disposed) {
            load();
          }
        },
      );
    } else {
      _fail('Không tìm thấy đơn hàng.');
    }
  }

  void _handleLoadError(dynamic error) {
    if (_disposed) return;

    if (_retryCount < _maxRetries) {
      _retryCount++;
      _isRetrying = true;
      _loading = false;
      _error = null;
      notifyListeners();

      debugPrint('QRPickup.retryAfterError: attempt $_retryCount/$_maxRetries');

      _retryTimer = Timer(
        const Duration(seconds: _retryDelaySeconds),
        () {
          if (!_disposed) {
            load();
          }
        },
      );
    } else {
      _fail('Không thể tải thông tin nhận món.');
    }
  }

  Future<Stream<store.OrderModel?>> _resolveOrderStream(String value) async {
    final byId = await _repository!.getOrder(value);
    if (byId != null) {
      return _repository!.watchOrder(byId.id);
    }
    final byCode = await _repository!.getOrderByCode(value);
    if (byCode != null) {
      return _repository!.watchOrder(byCode.id);
    }
    return Stream<store.OrderModel?>.value(null);
  }

  Future<void> refreshQrCode() => load();

  OrderModel _fromFirestore(store.OrderModel order) => OrderModel(
    id: order.orderCode.isEmpty ? order.id : order.orderCode,
    placedAt: _dateTime(order.createdAt),
    readyAt: _time(order.updatedAt),
    pickupCounter: order.pickupCounter,
    pickupDescription: order.items.isEmpty ? '' : order.items.first.name,
    paymentStatus: order.paymentStatus,
    paymentMethod: order.paymentMethod,
    orderStatus: order.orderStatus,
    isCancelled: order.orderStatus == 'cancelled',
    pickupEnabled: order.pickupEnabled,
    items: order.items
        .map(
          (item) => OrderItemModel(
            name: item.name,
            quantity: item.quantity,
            price: item.total,
            imageAsset: item.imageUrl,
          ),
        )
        .toList(growable: false),
  );

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} - ${_time(value)}';

  void _fail(String message) {
    if (_disposed) return;
    _loading = false;
    _isRetrying = false;
    _order = null;
    _qrData = '';
    _error = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

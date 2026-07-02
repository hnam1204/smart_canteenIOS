import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/app_settings_model.dart';
import '../../../models/firestore_models.dart' as store;
import '../../../repositories/app_settings_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import 'payment_model.dart';

enum PaymentConfirmation { cashAccepted, awaitingBankVerification, expired }

class PaymentController extends SafeChangeNotifier {
  PaymentController({required this.order, AppSettingsRepository? repository})
    : _settingsRepository = repository;

  static const int qrExpirySeconds = 10 * 60;

  final PaymentOrderModel order;
  AppSettingsRepository? _settingsRepository;

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  PaymentStatus _status = PaymentStatus.pending;
  PaymentSettingsModel _paymentSettings = PaymentSettingsModel.fallback;
  int _secondsRemaining = qrExpirySeconds;
  int _qrSession = 1;
  bool _submitting = false;
  bool _manualTransferSubmitting = false;
  bool _customerConfirmedTransfer = false;
  bool _creatingBankSession = false;
  bool _disposed = false;
  Timer? _timer;
  StreamSubscription<store.OrderModel?>? _orderSubscription;
  store.OrderModel? _latestOrder;
  String? _bankOrderId;
  String? _errorMessage;
  DateTime? _paidAt;

  PaymentMethod get selectedMethod => _selectedMethod;
  PaymentStatus get status => _status;
  int get secondsRemaining => _secondsRemaining;
  bool get submitting => _submitting;
  bool get manualTransferSubmitting => _manualTransferSubmitting;
  bool get customerConfirmedTransfer => _customerConfirmedTransfer;
  bool get creatingBankSession => _creatingBankSession;
  PaymentSettingsModel get paymentSettings => _paymentSettings;
  store.OrderModel? get latestOrder => _latestOrder;
  String? get bankOrderId => _bankOrderId;
  String? get errorMessage => _errorMessage;
  DateTime? get paidAt => _paidAt;
  bool get isWaitingForBankPayment =>
      _selectedMethod == PaymentMethod.bankQr &&
      _bankOrderId != null &&
      _status == PaymentStatus.pending;

  QrPaymentModel get qrPayment => QrPaymentModel(
    amount: order.total,
    description: order.transferDescription,
    session: _qrSession,
    settings: _paymentSettings,
  );

  Future<void> loadPaymentSettings() async {
    if (Firebase.apps.isEmpty) return;
    try {
      _settingsRepository ??= AppSettingsRepository();
      _paymentSettings = await _settingsRepository!.getPaymentSettings();
      if (!_disposed) notifyListeners();
    } catch (error) {
      debugPrint('Payment settings fallback: $error');
      _paymentSettings = PaymentSettingsModel.fallback;
      notifyListeners();
    }
  }

  void selectMethod(PaymentMethod method) {
    if (_selectedMethod == method) return;
    _selectedMethod = method;
    _status = PaymentStatus.pending;
    _errorMessage = null;
    if (method == PaymentMethod.bankQr) {
      refreshQr();
    } else {
      _timer?.cancel();
      unawaited(_orderSubscription?.cancel());
      _orderSubscription = null;
    }
    if (!_disposed) notifyListeners();
  }

  void refreshQr() {
    _qrSession++;
    _secondsRemaining = qrExpirySeconds;
    _status = PaymentStatus.pending;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 1) {
        _status = PaymentStatus.expired;
        _secondsRemaining = 0;
        _emit();
        return;
      }
      if (_status == PaymentStatus.paid) {
        _timer?.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        _emit();
      }
    });
    _emit();
  }

  void markBankSessionCreating(bool creating) {
    if (_creatingBankSession == creating) return;
    _creatingBankSession = creating;
    _emit();
  }

  Future<void> bindBankOrder({
    required String orderId,
    OrderRepository? repository,
  }) async {
    if (orderId.trim().isEmpty || _bankOrderId == orderId) return;
    _bankOrderId = orderId;
    _errorMessage = null;
    _latestOrder = null;
    _paidAt = null;
    _customerConfirmedTransfer = false;
    _status = PaymentStatus.pending;
    refreshQr();

    if (Firebase.apps.isEmpty) {
      _emit();
      return;
    }

    await _orderSubscription?.cancel();
    _orderSubscription = (repository ?? OrderRepository())
        .watchOrder(orderId)
        .listen(
          (order) {
            if (_disposed) return;
            _latestOrder = order;
            _errorMessage = null;
            _customerConfirmedTransfer =
                order?.customerConfirmedTransfer ?? _customerConfirmedTransfer;

            final paymentStatus =
                order?.paymentStatus.trim().toLowerCase() ?? '';
            if (paymentStatus == 'paid') {
              _status = PaymentStatus.paid;
              _paidAt = order?.updatedAt ?? DateTime.now();
              _timer?.cancel();
              unawaited(_orderSubscription?.cancel());
              _orderSubscription = null;
            } else if (paymentStatus == 'expired' ||
                paymentStatus == 'failed') {
              _status = PaymentStatus.expired;
              _secondsRemaining = 0;
              _timer?.cancel();
            } else if (_status != PaymentStatus.expired) {
              _status = PaymentStatus.pending;
            }

            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Payment order listener failed: $error\n$stackTrace');
            _errorMessage = 'Không thể theo dõi thanh toán. Vui lòng thử lại.';
            _emit();
          },
        );
  }

  void setManualTransferSubmitting(bool submitting) {
    if (_manualTransferSubmitting == submitting) return;
    _manualTransferSubmitting = submitting;
    _emit();
  }

  void markCustomerTransferConfirmed() {
    if (_customerConfirmedTransfer) return;
    _customerConfirmedTransfer = true;
    _emit();
  }

  Future<PaymentConfirmation> confirmPayment() async {
    if (_submitting) return PaymentConfirmation.expired;
    _submitting = true;
    notifyListeners();
    if (_selectedMethod == PaymentMethod.bankQr &&
        _status == PaymentStatus.expired) {
      _submitting = false;
      notifyListeners();
      return PaymentConfirmation.expired;
    }
    if (_selectedMethod == PaymentMethod.bankQr) {
      _submitting = false;
      notifyListeners();
      return PaymentConfirmation.awaitingBankVerification;
    }
    _submitting = false;
    _timer?.cancel();
    notifyListeners();
    return PaymentConfirmation.cashAccepted;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_orderSubscription?.cancel());
    super.dispose();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }
}

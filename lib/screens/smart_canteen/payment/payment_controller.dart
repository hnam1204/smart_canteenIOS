import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/app_settings_model.dart';
import '../../../repositories/app_settings_repository.dart';
import 'payment_model.dart';

enum PaymentConfirmation { cashAccepted, awaitingBankVerification, expired }

class PaymentController extends ChangeNotifier {
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
  bool _disposed = false;
  Timer? _timer;

  PaymentMethod get selectedMethod => _selectedMethod;
  PaymentStatus get status => _status;
  int get secondsRemaining => _secondsRemaining;
  bool get submitting => _submitting;
  PaymentSettingsModel get paymentSettings => _paymentSettings;

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
    if (method == PaymentMethod.bankQr) {
      refreshQr();
    } else {
      _timer?.cancel();
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
        notifyListeners();
        refreshQr();
        return;
      }
      _secondsRemaining--;
      notifyListeners();
    });
    notifyListeners();
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
    super.dispose();
  }
}

import '../core/utils/perf_logger.dart';
import '../core/utils/repository_cache.dart';
import '../firebase/firestore_service.dart';
import '../models/app_settings_model.dart';

class AppSettingsRepository {
  AppSettingsRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;
  static CacheEntry<PaymentSettingsModel>? _paymentSettingsCache;
  static Future<PaymentSettingsModel>? _inFlightPaymentSettings;
  static const Duration _paymentSettingsTtl = Duration(minutes: 15);

  Future<PaymentSettingsModel> getPaymentSettings() async {
    final cached = _paymentSettingsCache;
    if (cached != null && cached.isValid(_paymentSettingsTtl)) {
      return cached.data;
    }
    final inFlight = _inFlightPaymentSettings;
    if (inFlight != null) return inFlight;

    final request = traceAsync('loadAppSettings.payment', () async {
      final settings = await _service.getDocument<PaymentSettingsModel>(
        document: _service.collection('app_settings').doc('payment'),
        fromFirestore: PaymentSettingsModel.fromFirestore,
      );
      final resolved = settings ?? PaymentSettingsModel.fallback;
      _paymentSettingsCache = CacheEntry(
        data: resolved,
        cachedAt: DateTime.now(),
      );
      return resolved;
    });
    _inFlightPaymentSettings = request;
    try {
      return await request;
    } finally {
      _inFlightPaymentSettings = null;
    }
  }
}

import '../firebase/firestore_service.dart';
import '../models/app_settings_model.dart';

class AppSettingsRepository {
  AppSettingsRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Future<PaymentSettingsModel> getPaymentSettings() async {
    final settings = await _service.getDocument<PaymentSettingsModel>(
      document: _service.collection('app_settings').doc('payment'),
      fromFirestore: PaymentSettingsModel.fromFirestore,
    );
    return settings ?? PaymentSettingsModel.fallback;
  }
}

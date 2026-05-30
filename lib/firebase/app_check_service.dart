import 'package:flutter/foundation.dart';

class AppCheckService {
  AppCheckService._();

  static Future<void> activateForRelease() async {
    if (kDebugMode) {
      debugPrint('App Check disabled in debug mode');
    }

    // Tạm tắt Firebase App Check vì iOS app chưa được register App Check.
    // Khi nào cần bật lại:
    // Firebase Console → App Check → Register iOS app → DeviceCheck/App Attest
    return;
  }
}
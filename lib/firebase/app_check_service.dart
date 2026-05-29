import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  AppCheckService._();

  static Future<void> activateForRelease() async {
    if (!kReleaseMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  }
}

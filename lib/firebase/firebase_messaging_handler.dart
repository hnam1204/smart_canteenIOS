import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    final options = DefaultFirebaseOptions.maybeCurrentPlatform;
    if (options == null) {
      if (kDebugMode) {
        debugPrint('FCM background skipped: Firebase is not configured.');
      }
      return;
    }
    await Firebase.initializeApp(options: options);
  }
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId ?? 'unknown'}');
  }
}

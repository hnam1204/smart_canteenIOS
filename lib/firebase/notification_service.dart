import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/security/secure_storage_service.dart';

typedef NotificationTapHandler = void Function(RemoteMessage message);

class NotificationService {
  NotificationService._({
    FirebaseMessaging? messaging,
    SecureStorageService? secureStorage,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _secureStorage = secureStorage ?? SecureStorageService();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging;
  final SecureStorageService _secureStorage;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _initialized = false;

  Future<AuthorizationStatus> initialize({
    NotificationTapHandler? onNotificationTap,
    bool requestPermission = true,
  }) async {
    if (_initialized) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus;
    }
    _initialized = true;
    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = requestPermission
        ? await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          )
        : await _messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _persistCurrentToken();
    }

    _subscriptions
      ..add(_messaging.onTokenRefresh.listen(_saveToken))
      ..add(
        FirebaseMessaging.onMessage.listen((message) {
          if (kDebugMode) {
            debugPrint(
              'FCM foreground message: ${message.messageId ?? 'unknown'}',
            );
          }
        }),
      )
      ..add(
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          onNotificationTap?.call(message);
        }),
      );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) onNotificationTap?.call(initialMessage);
    return settings.authorizationStatus;
  }

  Future<String?> get apnsToken => _messaging.getAPNSToken();

  Future<void> syncTokenForCurrentUser() => _persistCurrentToken();

  Future<void> _persistCurrentToken() async {
    final vapidKey = kIsWeb ? AppConfig.firebaseWebVapidKey : null;
    if (kIsWeb && vapidKey == null) {
      if (kDebugMode) {
        debugPrint(
          'FCM web token skipped: configure FIREBASE_WEB_VAPID_KEY first.',
        );
      }
      return;
    }
    try {
      final token = await _messaging.getToken(vapidKey: vapidKey);
      if (token != null) await _saveToken(token);
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('FCM token registration unavailable: $error');
      }
    }
  }

  Future<void> _saveToken(String token) async {
    await _secureStorage.writeFcmToken(token);
    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('fcmTokens')
              .doc(token.hashCode.toUnsigned(32).toRadixString(16))
              .set({
                'token': token,
                'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } on FirebaseException catch (error) {
          if (kDebugMode) {
            debugPrint('FCM token sync skipped: ${error.message}');
          }
        }
      }
    }
    if (kDebugMode) {
      final visible = token.length > 12
          ? '${token.substring(0, 12)}...'
          : token;
      debugPrint('FCM token registered: $visible');
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }
}

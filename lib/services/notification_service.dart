import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show appNavigatorKey;
import '../screens/smart_canteen/help_center/support_chat_screen.dart';
import '../screens/smart_canteen/main_shell_screen.dart';
import '../screens/smart_canteen/notifications/notification_detail_screen.dart';
import '../screens/smart_canteen/order_history/order_detail_screen.dart';
import '../screens/smart_canteen/payment/payment_detail_screen.dart';
import '../screens/smart_canteen/promotion/promotion_screen.dart';
import '../screens/smart_canteen/reward_points/reward_points_screen.dart';
import '../screens/smart_canteen/vouchers/my_vouchers_screen.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Configure foreground presentation behavior for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize Local Notifications
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;
            handleNotificationTap(data);
          } catch (e) {
            debugPrint('Error parsing notification response: $e');
          }
        }
      },
    );

    // Setup message event listeners
    listenForegroundMessages();
    listenBackgroundMessages();

    // Tap callback while in background/terminated
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        handleNotificationTap(message.data);
      }),
    );

    // Check if app was opened from terminated state by a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage.data);
    }

    // Refresh token listener
    _subscriptions.add(
      _messaging.onTokenRefresh.listen((token) {
        saveTokenToFirestore(token);
      }),
    );

    // Attempt token retrieval and Firestore registration
    await getFCMToken();
  }

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _showSettingsDialog();
      return false;
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await saveTokenToFirestore(token);
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmToken': token,
        'notificationEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  Future<void> removeTokenFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error removing FCM token from Firestore: $e');
    }
  }

  void listenForegroundMessages() {
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Foreground message received: ${message.messageId}');
        await _showLocalNotification(message);
        await updateBadgeCount();
      }),
    );
  }

  void listenBackgroundMessages() {
    // The background handler is set via FirebaseMessaging.onBackgroundMessage in main.dart
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformChannelSpecifics = NotificationDetails(
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  Future<void> updateBadgeCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      final count = snapshot.docs.length;
      await setBadge(count);
    } catch (e) {
      debugPrint('Error querying unread notification count for badge: $e');
    }
  }

  static const MethodChannel _badgeChannel = MethodChannel('com.huflit.smart_canteen/badge');
  Future<void> setBadge(int count) async {
    try {
      await _badgeChannel.invokeMethod('setBadge', count);
    } catch (e) {
      debugPrint('Error setting badge count natively: $e');
    }
  }

  static const MethodChannel _settingsChannel = MethodChannel('com.huflit.smart_canteen/settings');
  Future<void> openAppSettings() async {
    try {
      await _settingsChannel.invokeMethod('openSettings');
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  void _showSettingsDialog() {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Quyền thông báo'),
        content: const Text(
          'Quyền nhận thông báo hiện đang bị từ chối. Vui lòng mở Cài đặt để bật quyền thông báo cho ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B00)),
            child: const Text('Đi tới Cài đặt'),
          ),
        ],
      ),
    );
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final referenceId = data['referenceId'] as String? ?? '';
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final Widget destination;
    switch (type) {
      case 'order':
        destination = OrderDetailScreen(orderId: referenceId);
        break;
      case 'payment':
        destination = PaymentDetailScreen(paymentId: referenceId);
        break;
      case 'support':
        destination = SupportChatScreen(ticketId: referenceId);
        break;
      case 'voucher':
        destination = const MyVouchersScreen();
        break;
      case 'reward':
        destination = const RewardPointsScreen();
        break;
      case 'promotion':
        destination = const PromotionScreen();
        break;
      case 'system':
        destination = NotificationDetailScreen(notificationId: referenceId);
        break;
      default:
        destination = const MainShellScreen(initialIndex: 3); // Notification tab in main shell
        break;
    }

    appNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }
}

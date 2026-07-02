import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show appNavigatorKey;
import '../core/utils/app_feedback.dart';
import '../screens/smart_canteen/help_center/support_chat_screen.dart';
import '../screens/smart_canteen/main_shell_screen.dart';
import '../screens/smart_canteen/notifications/notification_detail_screen.dart';
import '../screens/smart_canteen/order_history/order_detail_screen.dart';
import '../screens/smart_canteen/payment/payment_detail_screen.dart';
import '../screens/smart_canteen/promotion/promotion_screen.dart';
import '../screens/smart_canteen/reward_points/reward_points_screen.dart';
import '../screens/smart_canteen/vouchers/my_vouchers_screen.dart';
import '../screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  DateTime? _listenerStartTime;
  final Set<String> _shownNotificationIds = {};
  bool _dialogShowing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to Firebase Auth changes to bind/unbind Firestore realtime notifications stream
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startListening(user.uid);
      } else {
        stopListening();
      }
    });
  }

  void startListening(String userId) {
    stopListening();
    _listenerStartTime = DateTime.now();
    _shownNotificationIds.clear();

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10) // Fetch top 10 to listen to new ones
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isEmpty) return;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final docId = doc.id;

            // Skip if notification has already been processed/shown
            if (_shownNotificationIds.contains(docId)) continue;

            final createdAt = data['createdAt'];

            // Skip if this is an old historical notification
            if (createdAt is Timestamp) {
              final docTime = createdAt.toDate();
              if (_listenerStartTime != null &&
                  docTime.isBefore(
                    _listenerStartTime!.subtract(const Duration(seconds: 5)),
                  )) {
                // Pre-add existing notifications to set so they won't trigger banners upon launch
                _shownNotificationIds.add(docId);
                continue;
              }
            }

            // We only show banners for unread notifications
            final isRead = data['isRead'] as bool? ?? false;
            if (isRead) continue;

            // Mark as processed/shown
            _shownNotificationIds.add(docId);

            final title = data['title'] as String? ?? '';
            final message = data['message'] as String? ?? '';
            final type = data['type'] as String? ?? 'system';
            final referenceId = data['referenceId'] as String? ?? '';

            // Show custom in-app banner or dialog
            final orderId = _resolveOrderReference(data);
            if ((type == 'order_ready' || type == 'order_ready_reminder') && orderId.isNotEmpty) {
              final context = appNavigatorKey.currentContext;
              if (context != null) {
                if (!context.mounted) continue;
                final orderCode =
                    data['orderCode'] as String? ??
                    (data['data'] as Map?)?['orderCode'] as String? ??
                    referenceId;
                _showOrderReadyDialog(
                  context,
                  message,
                  orderId,
                  orderCode,
                  docId,
                );
              }
            } else {
              showInAppBanner(
                title: title,
                message: message,
                type: type,
                referenceId: referenceId,
              );
            }
          }
        });
  }

  String _resolveOrderReference(Map<String, dynamic> data) {
    final nested = data['data'] is Map ? data['data'] as Map : const {};
    final candidates = [
      data['orderId'],
      data['referenceId'],
      nested['orderId'],
      data['orderCode'],
      nested['orderCode'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<void> _markNotificationRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
          'isRead': true,
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  void _showOrderReadyDialog(
    BuildContext context,
    String message,
    String orderId,
    String orderCode,
    String notificationId,
  ) {
    if (_dialogShowing) return;
    _dialogShowing = true;

    // Trigger haptic feedback
    HapticFeedback.vibrate().catchError((_) {});

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              color: Color(0xFFFF6B00),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Món đã sẵn sàng',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(_markNotificationRead(notificationId));
              appNavigatorKey.currentState?.pushNamed(
                '/qr-pickup',
                arguments: {
                  'orderId': orderId,
                  'referenceId': orderId,
                  'orderCode': orderCode,
                },
              );
            },
            child: const Text(
              'Xem QR nhận món',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
        ],
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }

  void stopListening() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _shownNotificationIds.clear();
    _dialogShowing = false;
  }

  void showInAppBanner({
    required String title,
    required String message,
    required String type,
    required String referenceId,
  }) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    // Trigger haptic feedback
    HapticFeedback.lightImpact().catchError((_) {});

    // Create and insert overlay entry
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        title: title,
        message: message,
        type: type,
        referenceId: referenceId,
        onDismiss: () {
          try {
            overlayEntry.remove();
          } catch (_) {}
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final resolvedReference = _resolveOrderReference(data);
    final referenceId = resolvedReference.isNotEmpty
        ? resolvedReference
        : (data['referenceId'] as String? ?? '');
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final bool needsReferenceId = const [
      'order',
      'order_ready',
      'order_ready_reminder',
      'payment',
      'support',
      'system',
    ].contains(type);

    if (needsReferenceId && referenceId.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Thông báo không có mã tham chiếu hợp lệ.',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
      );
      return;
    }

    final Widget destination;
    switch (type) {
      case 'order':
        destination = OrderDetailScreen(orderId: referenceId);
        break;
      case 'order_ready':
      case 'order_ready_reminder':
        destination = QRPickupScreen(orderId: referenceId);
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
        destination = const MainShellScreen(
          initialIndex: 3,
        ); // Notification tab in main shell
        break;
    }

    appNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Stubs for Backwards Compatibility
  // ────────────────────────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    return true; // Auto approved for in-app client-side listeners
  }

  Future<String?> getFCMToken() async {
    return null;
  }

  Future<void> saveTokenToFirestore(String token) async {
    // Stub
  }

  Future<void> removeTokenFromFirestore() async {
    // Stub
  }

  static const MethodChannel _badgeChannel = MethodChannel(
    'com.huflit.smart_canteen/badge',
  );
  Future<void> setBadge(int count) async {
    try {
      await _badgeChannel.invokeMethod('setBadge', count);
    } catch (e) {
      debugPrint('Error setting badge count natively: $e');
    }
  }

  Future<void> dispose() async {
    stopListening();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }
}

class _InAppNotificationBanner extends StatefulWidget {
  const _InAppNotificationBanner({
    required this.title,
    required this.message,
    required this.type,
    required this.referenceId,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final String type;
  final String referenceId;
  final VoidCallback onDismiss;

  @override
  State<_InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto dismiss after 5 seconds
    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF2176E8);
      case 'payment':
        return const Color(0xFF13A457);
      case 'support':
        return const Color(0xFFFF6B00); // AppColors.primary
      case 'voucher':
        return const Color(0xFF13A457);
      case 'reward':
        return const Color(0xFF7C4DCC);
      case 'review':
        return const Color(0xFFE28743);
      case 'promotion':
        return const Color(0xFFFF6B00);
      case 'system':
        return const Color(0xFFE74680);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'support':
        return Icons.support_agent_rounded;
      case 'voucher':
        return Icons.card_giftcard_rounded;
      case 'reward':
        return Icons.celebration_rounded;
      case 'review':
        return Icons.rate_review_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'system':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top + 12;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: () {
            _dismissTimer?.cancel();
            _controller.reverse().then((_) {
              widget.onDismiss();
              NotificationService.instance.handleNotificationTap({
                'type': widget.type,
                'referenceId': widget.referenceId,
              });
            });
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < 0) {
              _dismiss();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _typeColor(widget.type).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _typeIcon(widget.type),
                      color: _typeColor(widget.type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                    onPressed: _dismiss,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

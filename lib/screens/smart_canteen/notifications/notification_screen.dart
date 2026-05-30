import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/review_repository.dart';
import '../main_shell_screen.dart';
import '../review/review_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'notification_controller.dart';
import 'notification_detail_screen.dart';
import 'notification_model.dart';
import '../help_center/support_chat_screen.dart';
import '../order_history/order_detail_screen.dart';
import '../payment/payment_detail_screen.dart';
import '../promotion/promotion_screen.dart';
import '../reward_points/reward_points_screen.dart';
import '../vouchers/my_vouchers_screen.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_tab.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    this.cartCount = 0,
    this.embedded = false,
    this.onTabSelected,
  });

  final int cartCount;
  final bool embedded;
  final ValueChanged<int>? onTabSelected;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replace(Widget screen) {
    AppNavigator.replace<void>(context, builder: (_) => screen);
  }

  void _onNavigationTap(int index) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }
    _replace(MainShellScreen(initialIndex: index));
  }

  void _markAllAsRead() {
    _controller.markAllAsRead();
    showAppSnackBar(context, 'Đã đánh dấu tất cả thông báo là đã đọc.');
  }

  void _openDetails(AppNotification notification) async {
    _controller.markAsRead(notification.id);

    // Route by type
    switch (notification.type) {
      case NotificationType.support:
        if (notification.referenceId.isNotEmpty) {
          AppNavigator.push<void>(
            context,
            builder: (_) => SupportChatScreen(ticketId: notification.referenceId),
          );
          return;
        }
      case NotificationType.order:
        if (notification.referenceId.isNotEmpty) {
          AppNavigator.push<void>(
            context,
            builder: (_) => OrderDetailScreen(orderId: notification.referenceId),
          );
          return;
        }
      case NotificationType.payment:
        if (notification.referenceId.isNotEmpty) {
          AppNavigator.push<void>(
            context,
            builder: (_) => PaymentDetailScreen(paymentId: notification.referenceId),
          );
          return;
        }
      case NotificationType.voucher:
        AppNavigator.push<void>(
          context,
          builder: (_) => const MyVouchersScreen(),
        );
        return;
      case NotificationType.reward:
        AppNavigator.push<void>(
          context,
          builder: (_) => const RewardPointsScreen(),
        );
        return;
      case NotificationType.promotion:
        AppNavigator.push<void>(
          context,
          builder: (_) => const PromotionScreen(),
        );
        return;
      case NotificationType.system:
        if (notification.referenceId.isNotEmpty) {
          AppNavigator.push<void>(
            context,
            builder: (_) => NotificationDetailScreen(notificationId: notification.referenceId),
          );
          return;
        }
      case NotificationType.review:
        if (notification.referenceId.isNotEmpty) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
          try {
            final order = await OrderRepository().getOrder(notification.referenceId)
                ?? await OrderRepository().getOrderByCode(notification.referenceId);
            if (mounted) Navigator.pop(context);

            if (order == null) {
              if (mounted) showAppSnackBar(context, 'Đơn hàng không tồn tại.');
              return;
            }

            final resolvedOrder = order;
            final existingReview = await ReviewRepository().getReviewForOrder(resolvedOrder.id);
            if (resolvedOrder.hasReview || existingReview != null) {
              if (mounted) showAppSnackBar(context, 'Bạn đã đánh giá đơn hàng này rồi.');
              return;
            }

            if (resolvedOrder.orderStatus != 'delivered' && resolvedOrder.orderStatus != 'completed') {
              if (mounted) {
                showAppSnackBar(context, 'Bạn chỉ có thể đánh giá sau khi đơn hàng đã hoàn thành.');
              }
              return;
            }

            if (mounted) {
              AppNavigator.push<void>(
                context,
                builder: (_) => ReviewScreen(
                  orderId: resolvedOrder.id,
                  cartCount: widget.cartCount,
                  notificationCount: _controller.unreadCount,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              showAppSnackBar(context, 'Đã xảy ra lỗi: ${e.toString()}');
            }
          }
          return;
        }
    }

    // Fallback: show detail sheet
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _NotificationDetailsSheet(notification: notification),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final items = _controller.visibleNotifications;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  unreadCount: _controller.unreadCount,
                  onSettingsTap: _openSettings,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  child: NotificationTab(
                    selectedFilter: _controller.filter,
                    onSelected: _controller.setFilter,
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _controller.loading
                        ? const _LoadingList(key: ValueKey('loading'))
                        : items.isEmpty
                        ? _EmptyNotifications(
                            key: const ValueKey('empty'),
                            onRefresh: _controller.refresh,
                          )
                        : RefreshIndicator(
                            key: const ValueKey('content'),
                            color: AppColors.primary,
                            onRefresh: _controller.refresh,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                              itemCount: items.length + 1,
                              itemBuilder: (context, index) {
                                if (index == items.length) {
                                  return _MarkReadButton(
                                    enabled: _controller.unreadCount > 0,
                                    onPressed: _markAllAsRead,
                                  );
                                }
                                final notification = items[index];
                                return NotificationCard(
                                  key: ValueKey(notification.id),
                                  notification: notification,
                                  onDetailsTap: () =>
                                      _openDetails(notification),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: widget.embedded
              ? null
              : CanteenBottomNavBar(
                  selectedIndex: 3,
                  cartCount: widget.cartCount,
                  notificationCount: _controller.unreadCount,
                  onTap: _onNavigationTap,
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unreadCount, required this.onSettingsTap});

  final int unreadCount;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: SizedBox(
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Cài đặt thông báo',
                  onPressed: onSettingsTap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 23),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: 5,
      itemBuilder: (context, index) => const _NotificationSkeleton(),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PulseBox(width: 55, height: 55, radius: 28),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _PulseBox(width: 198, height: 15, radius: 8),
                SizedBox(height: 12),
                _PulseBox(width: double.infinity, height: 12, radius: 7),
                SizedBox(height: 8),
                _PulseBox(width: 150, height: 12, radius: 7),
                SizedBox(height: 13),
                _PulseBox(width: 88, height: 12, radius: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseBox extends StatelessWidget {
  const _PulseBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.09),
          Center(
            child: Image.asset(
              'assets/images/empty_notifications.png',
              width: 172,
              height: 172,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chưa có thông báo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ưu đãi và cập nhật đơn hàng mới sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkReadButton extends StatelessWidget {
  const _MarkReadButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.mark_email_read_outlined, size: 19),
        label: Text(enabled ? 'Đánh dấu tất cả đã đọc' : 'Tất cả đã đọc'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          disabledForegroundColor: AppColors.textTertiary,
          side: const BorderSide(color: AppColors.divider),
          minimumSize: const Size(double.infinity, 51),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.paddingOf(context).bottom + 22,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: _SheetHandle()),
          const SizedBox(height: 19),
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            notification.message,
            style: const TextStyle(
              height: 1.5,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (notification.detail != null) ...[
            const SizedBox(height: 7),
            Text(
              notification.detail!,
              style: const TextStyle(
                height: 1.5,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Đã hiểu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _notifyOrder = true;
  bool _notifyPromotion = true;
  bool _notifySupport = true;
  bool _notifySystem = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final uid = _currentUid;
    if (uid == null) {
      setState(() => _loadingPrefs = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final settings = data['notificationSettings'] as Map<String, dynamic>? ?? {};
      setState(() {
        _notifyOrder = settings['order'] as bool? ?? data['notifyOrder'] as bool? ?? true;
        _notifyPromotion = settings['promotion'] as bool? ?? data['notifyPromotion'] as bool? ?? true;
        _notifySupport = settings['support'] as bool? ?? data['notifySupport'] as bool? ?? true;
        _notifySystem = settings['system'] as bool? ?? data['notifySystem'] as bool? ?? true;
        _loadingPrefs = false;
      });
    } catch (_) {
      setState(() => _loadingPrefs = false);
    }
  }

  String? get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _updatePref(String key, bool value) async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'notificationSettings': {
          key: value,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently ignore preference sync errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          const Text(
            'Cài đặt thông báo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingPrefs)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else ...[
            SwitchListTile.adaptive(
              value: _notifyOrder,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Đơn hàng'),
              subtitle: const Text('Cập nhật trạng thái đơn hàng'),
              onChanged: (value) {
                setState(() => _notifyOrder = value);
                _updatePref('order', value);
              },
            ),
            SwitchListTile.adaptive(
              value: _notifyPromotion,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Khuyến mãi'),
              subtitle: const Text('Ưu đãi và chương trình khuyến mãi'),
              onChanged: (value) {
                setState(() => _notifyPromotion = value);
                _updatePref('promotion', value);
              },
            ),
            SwitchListTile.adaptive(
              value: _notifySupport,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Hỗ trợ'),
              subtitle: const Text('Phản hồi từ nhân viên hỗ trợ'),
              onChanged: (value) {
                setState(() => _notifySupport = value);
                _updatePref('support', value);
              },
            ),
            SwitchListTile.adaptive(
              value: _notifySystem,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Hệ thống'),
              subtitle: const Text('Thông báo cập nhật từ hệ thống'),
              onChanged: (value) {
                setState(() => _notifySystem = value);
                _updatePref('system', value);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

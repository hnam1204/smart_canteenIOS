import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../notification_model.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDetailsTap,
  });

  final AppNotification notification;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final palette = _NotificationPalette.fromType(notification.type);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 15, 12, 14),
      decoration: BoxDecoration(
        color: notification.isUnread ? palette.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: notification.isUnread
              ? palette.accent.withValues(alpha: 0.12)
              : AppColors.divider.withValues(alpha: 0.8),
        ),
        boxShadow: notification.isUnread
            ? [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : const [],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIcon(palette: palette, icon: notification.type.icon),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact && notification.isNew) ...[
                      const _NewBadge(),
                      const SizedBox(height: 7),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact && notification.isNew) ...[
                          const _NewBadge(),
                          const SizedBox(width: 7),
                        ],
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TimeStatus(
                          label: notification.timeLabel,
                          unread: notification.isUnread,
                          color: palette.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (notification.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.detail!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    InkWell(
                      onTap: onDetailsTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem chi tiết',
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: palette.accent,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.palette, required this.icon});

  final _NotificationPalette palette;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: palette.iconBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: palette.accent, size: 29),
    );
  }
}

class _TimeStatus extends StatelessWidget {
  const _TimeStatus({
    required this.label,
    required this.unread,
    required this.color,
  });

  final String label;
  final bool unread;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (unread) ...[
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Mới',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

extension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.order:
        return Icons.receipt_long_outlined;
      case NotificationType.payment:
        return Icons.payment_rounded;
      case NotificationType.support:
        return Icons.support_agent_rounded;
      case NotificationType.voucher:
        return Icons.card_giftcard_rounded;
      case NotificationType.reward:
        return Icons.celebration_rounded;
      case NotificationType.review:
        return Icons.rate_review_rounded;
      case NotificationType.system:
        return Icons.campaign_rounded;
      case NotificationType.promotion:
        return Icons.local_offer_rounded;
    }
  }
}

class _NotificationPalette {
  const _NotificationPalette({
    required this.accent,
    required this.iconBackground,
    required this.surface,
  });

  final Color accent;
  final Color iconBackground;
  final Color surface;

  factory _NotificationPalette.fromType(NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return const _NotificationPalette(
          accent: AppColors.primary,
          iconBackground: Color(0xFFFFEBCF),
          surface: Color(0xFFFFFAF6),
        );
      case NotificationType.voucher:
        return const _NotificationPalette(
          accent: Color(0xFF13A457),
          iconBackground: Color(0xFFE7F7EE),
          surface: Color(0xFFF7FCF9),
        );
      case NotificationType.reward:
        return const _NotificationPalette(
          accent: Color(0xFF7C4DCC),
          iconBackground: Color(0xFFF0EAFB),
          surface: Color(0xFFFBF9FE),
        );
      case NotificationType.order:
        return const _NotificationPalette(
          accent: Color(0xFF2176E8),
          iconBackground: Color(0xFFE7F0FF),
          surface: Color(0xFFF7FAFF),
        );
      case NotificationType.payment:
        return const _NotificationPalette(
          accent: Color(0xFF13A457),
          iconBackground: Color(0xFFE7F7EE),
          surface: Color(0xFFF7FCF9),
        );
      case NotificationType.system:
        return const _NotificationPalette(
          accent: Color(0xFFE74680),
          iconBackground: Color(0xFFFDEAF1),
          surface: Color(0xFFFFFAFC),
        );
      case NotificationType.review:
        return const _NotificationPalette(
          accent: Color(0xFFE28743),
          iconBackground: Color(0xFFFBEEDD),
          surface: Color(0xFFFEF9F5),
        );
      case NotificationType.support:
        return const _NotificationPalette(
          accent: AppColors.primary,
          iconBackground: AppColors.primarySoft,
          surface: Color(0xFFFFFAF7),
        );
    }
  }
}

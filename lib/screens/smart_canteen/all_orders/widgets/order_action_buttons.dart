import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';

class OrderActionButtons extends StatelessWidget {
  const OrderActionButtons({
    super.key,
    required this.order,
    required this.onDetailsTap,
    required this.onCancelTap,
    required this.onTrackTap,
    required this.onQrTap,
    required this.onReviewTap,
    required this.onReorderTap,
    this.includeDetails = true,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onCancelTap;
  final VoidCallback onTrackTap;
  final VoidCallback onQrTap;
  final VoidCallback onReviewTap;
  final VoidCallback onReorderTap;
  final bool includeDetails;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 320;
        final buttons = _buttonsForStatus();
        return vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    buttons[index],
                    if (index != buttons.length - 1) const SizedBox(height: 9),
                  ],
                ],
              )
            : Row(
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    Expanded(child: buttons[index]),
                    if (index != buttons.length - 1) const SizedBox(width: 9),
                  ],
                ],
              );
      },
    );
  }

  List<Widget> _buttonsForStatus() {
    return switch (order.status) {
      OrderStatus.pending => [
        _OutlinedAction(
          key: ValueKey('cancel-${order.id}'),
          label: 'Hủy đơn',
          icon: Icons.close_rounded,
          danger: true,
          onTap: onCancelTap,
        ),
        if (order.pickupEnabled)
          _OutlinedAction(
            key: ValueKey('qr-${order.id}'),
            label: 'Xem QR',
            icon: Icons.qr_code_rounded,
            onTap: onQrTap,
          ),
        if (includeDetails)
          _FilledAction(
            key: ValueKey('detail-${order.id}'),
            label: 'Xem chi tiết',
            icon: Icons.arrow_forward_rounded,
            onTap: onDetailsTap,
          ),
      ],
      OrderStatus.preparing => [
        _OutlinedAction(
          key: ValueKey('track-${order.id}'),
          label: 'Theo dõi',
          icon: Icons.location_searching_rounded,
          onTap: onTrackTap,
        ),
        if (order.pickupEnabled)
          _OutlinedAction(
            key: ValueKey('qr-${order.id}'),
            label: 'Xem QR',
            icon: Icons.qr_code_rounded,
            onTap: onQrTap,
          ),
        if (includeDetails)
          _FilledAction(
            key: ValueKey('detail-${order.id}'),
            label: 'Xem chi tiết',
            icon: Icons.arrow_forward_rounded,
            onTap: onDetailsTap,
          ),
      ],
      OrderStatus.delivering => [
        _OutlinedAction(
          key: ValueKey('track-${order.id}'),
          label: 'Theo dõi',
          icon: Icons.location_searching_rounded,
          onTap: onTrackTap,
        ),
        if (includeDetails)
          _FilledAction(
            key: ValueKey('detail-${order.id}'),
            label: 'Xem chi tiết',
            icon: Icons.arrow_forward_rounded,
            onTap: onDetailsTap,
          ),
      ],
      OrderStatus.delivered || OrderStatus.completed => [
        _FilledAction(
          key: ValueKey('review-${order.id}'),
          label: order.hasReview ? 'Đã đánh giá' : 'Đánh giá',
          icon: Icons.star_rounded,
          onTap: order.hasReview ? null : onReviewTap,
        ),
        _OutlinedAction(
          key: ValueKey('reorder-${order.id}'),
          label: 'Mua lại',
          icon: Icons.replay_rounded,
          onTap: onReorderTap,
        ),
      ],
      OrderStatus.cancelled => [
        _FilledAction(
          key: ValueKey('reorder-${order.id}'),
          label: 'Đặt lại',
          icon: Icons.replay_rounded,
          onTap: onReorderTap,
        ),
      ],
    };
  }
}

class _FilledAction extends StatelessWidget {
  const _FilledAction({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.divider,
        disabledForegroundColor: AppColors.textTertiary,
        minimumSize: const Size(0, 43),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 43),
        side: BorderSide(color: color.withValues(alpha: 0.52)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

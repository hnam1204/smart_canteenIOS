import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'order_food_item.dart';
import 'order_status_chip.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onDetailsTap,
    required this.onQrTap,
    required this.onReviewTap,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onQrTap;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 375;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        16,
        compact ? 14 : 16,
        15,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _OrderHeader(order: order, onTap: onDetailsTap),
          const SizedBox(height: 14),
          if (compact) ...[
            _FoodList(items: order.items),
            const SizedBox(height: 14),
            _OrderActions(
              order: order,
              onDetailsTap: onDetailsTap,
              onQrTap: onQrTap,
              onReviewTap: onReviewTap,
              fullWidth: true,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _FoodList(items: order.items)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 146,
                  child: _OrderActions(
                    order: order,
                    onDetailsTap: onDetailsTap,
                    onQrTap: onQrTap,
                    onReviewTap: onReviewTap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Mã đơn: ',
                  children: [
                    TextSpan(
                      text: order.id,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OrderStatusChip(status: order.status),
            IconButton(
              tooltip: 'Chi tiết đơn hàng',
              onPressed: onTap,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '${order.date}  •  ${order.time}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            _PaymentBadge(status: order.paymentStatus),
            const SizedBox(width: 8),
            Text(
              _formatCurrency(order.total),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({required this.items});

  final List<OrderItemModel> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 91,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => OrderFoodItem(item: items[index]),
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.onDetailsTap,
    required this.onQrTap,
    required this.onReviewTap,
    this.fullWidth = false,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onQrTap;
  final VoidCallback onReviewTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderHistoryStatus.cancelled) {
      return _StatusAction(
        foreground: AppColors.error,
        background: const Color(0xFFFFF1F1),
        icon: Icons.cancel_outlined,
        title: 'Đã hủy đơn hàng',
        subtitle: order.cancelledAt,
      );
    }
    if (order.status == OrderHistoryStatus.preparing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailButton(onTap: onDetailsTap),
          const SizedBox(height: 8),
          _StatusAction(
            foreground: const Color(0xFF1976D2),
            background: const Color(0xFFEAF4FF),
            icon: Icons.schedule_outlined,
            title: 'Dự kiến sẵn sàng',
            subtitle: order.readyAt,
          ),
          if (order.pickupEnabled) ...[
            const SizedBox(height: 8),
            _QrButton(buttonKey: ValueKey('qr-${order.id}'), onTap: onQrTap, fullWidth: fullWidth),
          ],
        ],
      );
    }
    if (order.status == OrderHistoryStatus.pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailButton(onTap: onDetailsTap),
          const SizedBox(height: 8),
          const _StatusAction(
            foreground: AppColors.primary,
            background: AppColors.primarySoft,
            icon: Icons.hourglass_top_rounded,
            title: 'Chờ xác nhận',
            subtitle: 'Đang xử lý',
          ),
          if (order.pickupEnabled) ...[
            const SizedBox(height: 8),
            _QrButton(buttonKey: ValueKey('qr-${order.id}'), onTap: onQrTap, fullWidth: fullWidth),
          ],
        ],
      );
    }
    
    final isDeliveredOrCompleted = order.status == OrderHistoryStatus.delivered || order.status == OrderHistoryStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailButton(onTap: onDetailsTap),
        if (isDeliveredOrCompleted) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: ValueKey('review-${order.id}'),
            onPressed: order.hasReview ? null : onReviewTap,
            icon: Icon(order.hasReview ? Icons.star_rounded : Icons.star_outline_rounded, size: 18),
            label: Text(order.hasReview ? 'Đã đánh giá' : 'Đánh giá'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textTertiary,
              side: const BorderSide(color: AppColors.primaryLight),
              minimumSize: Size(fullWidth ? double.infinity : 0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (order.pickupEnabled) ...[
          const SizedBox(height: 8),
          _QrButton(buttonKey: ValueKey('qr-${order.id}'), onTap: onQrTap, fullWidth: fullWidth),
        ],
      ],
    );
  }
}

class _QrButton extends StatelessWidget {
  const _QrButton({required this.buttonKey, required this.onTap, required this.fullWidth});
  final Key buttonKey;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: buttonKey,
      onPressed: onTap,
      icon: const Icon(Icons.qr_code_rounded, size: 18),
      label: const Text('Xem mã QR'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: Size(fullWidth ? double.infinity : 0, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        textStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.trim()) {
      'pending' => AppColors.primary,
      'unpaid' || 'cashOnPickup' => AppColors.textSecondary,
      'paid' => AppColors.success,
      'failed' || 'expired' => AppColors.error,
      'refunded' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };
    final label = switch (status.trim()) {
      'pending' => 'Chờ xác nhận CK',
      'unpaid' || 'cashOnPickup' => 'Tại quầy',
      'paid' => 'Đã thanh toán',
      'failed' => 'Thất bại',
      'expired' => 'Hết hạn',
      'refunded' => 'Đã hoàn tiền',
      _ => 'Chưa rõ',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primaryLight),
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      child: const Text('Xem chi tiết'),
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({
    required this.foreground,
    required this.background,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int value) {
  final digits = value.toString();
  final result = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return '$resultđ';
}

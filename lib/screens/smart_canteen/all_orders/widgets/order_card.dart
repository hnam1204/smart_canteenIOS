import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../all_orders_controller.dart';
import '../order_model.dart';
import 'order_action_buttons.dart';
import 'order_status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onDetailsTap,
    required this.onCancelTap,
    required this.onTrackTap,
    required this.onQrTap,
    required this.onReviewTap,
    required this.onReorderTap,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onCancelTap;
  final VoidCallback onTrackTap;
  final VoidCallback onQrTap;
  final VoidCallback onReviewTap;
  final VoidCallback onReorderTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      order.orderedAt,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AllOrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          _OrderItemsPreview(order: order),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nhận tại ${order.pickupCounter}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              _PaymentBadge(status: order.paymentStatus),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Text(
                '${order.itemCount} món',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const Spacer(),
              Text(
                formatOrderCurrency(order.total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          OrderActionButtons(
            order: order,
            onDetailsTap: onDetailsTap,
            onCancelTap: onCancelTap,
            onTrackTap: onTrackTap,
            onQrTap: onQrTap,
            onReviewTap: onReviewTap,
            onReorderTap: onReorderTap,
          ),
        ],
      ),
    );
  }
}

class _OrderItemsPreview extends StatelessWidget {
  const _OrderItemsPreview({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) {
      return const Text(
        'Đơn hàng chưa có món',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AppFoodImage(
            source: order.items.first.imageAsset,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.items.first.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                order.items.length > 1
                    ? '+ ${order.items.length - 1} món khác'
                    : 'Số lượng: ${order.items.first.quantity}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PaymentStatus.pending => AppColors.primary,
      PaymentStatus.unpaid => AppColors.textSecondary,
      PaymentStatus.paid => AppColors.success,
      PaymentStatus.failed || PaymentStatus.expired => AppColors.error,
      PaymentStatus.refunded => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        paymentStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

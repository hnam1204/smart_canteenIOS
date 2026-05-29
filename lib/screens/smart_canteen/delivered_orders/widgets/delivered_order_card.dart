import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../order_model.dart';
import 'delivered_action_buttons.dart';
import 'delivered_status_banner.dart';

class DeliveredOrderCard extends StatelessWidget {
  const DeliveredOrderCard({
    super.key,
    required this.order,
    required this.onDetailsTap,
    required this.onReviewTap,
    required this.onReorderTap,
    required this.onInvoiceTap,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onReviewTap;
  final VoidCallback onReorderTap;
  final VoidCallback onInvoiceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                      'Đặt: ${order.orderedAt}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Giao: ${order.deliveredAt}',
                      style: const TextStyle(
                        color: deliveredGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _DeliveredChip(),
                  if (!order.reviewed) ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'Chưa đánh giá',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          _OrderPreview(order: order),
          const SizedBox(height: 12),
          _DeliveryLine(
            icon: Icons.location_on_outlined,
            value: order.delivery.destination,
          ),
          const SizedBox(height: 8),
          _DeliveryLine(
            icon: Icons.delivery_dining_outlined,
            value: '${order.delivery.shipperName} • ${order.delivery.phone}',
          ),
          if (order.note != null) ...[
            const SizedBox(height: 8),
            _DeliveryLine(
              icon: Icons.sticky_note_2_outlined,
              value: 'Ghi chú: ${order.note}',
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.itemCount} món • ${paymentMethodLabel(order.paymentMethod)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatCurrency(order.total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          DeliveredActionButtons(
            order: order,
            onDetailsTap: onDetailsTap,
            onReviewTap: onReviewTap,
            onReorderTap: onReorderTap,
            onInvoiceTap: onInvoiceTap,
          ),
        ],
      ),
    );
  }
}

class _DeliveredChip extends StatelessWidget {
  const _DeliveredChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: deliveredGreen.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Text(
        'Đã giao',
        style: TextStyle(
          color: deliveredGreen,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderPreview extends StatelessWidget {
  const _OrderPreview({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
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

class _DeliveryLine extends StatelessWidget {
  const _DeliveryLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: deliveredGreen, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

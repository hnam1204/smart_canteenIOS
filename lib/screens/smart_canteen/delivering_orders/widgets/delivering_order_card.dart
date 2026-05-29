import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../order_model.dart';
import 'delivery_info_widget.dart';
import 'delivery_progress_timeline.dart';
import 'delivery_status_banner.dart';
import 'map_preview_card.dart';

class DeliveringOrderCard extends StatelessWidget {
  const DeliveringOrderCard({
    super.key,
    required this.order,
    required this.onDetailsTap,
    required this.onContactTap,
    required this.onTrackTap,
    required this.onReviewTap,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onContactTap;
  final VoidCallback onTrackTap;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    final completed = order.status == OrderStatus.completed;
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
                      order.orderedAt,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(completed: completed),
            ],
          ),
          const SizedBox(height: 13),
          _OrderPreview(order: order),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              final location = Row(
                children: [
                  const Icon(
                    Icons.pin_drop_outlined,
                    size: 16,
                    color: deliveryGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.delivery.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              );
              final payment = Text(
                paymentMethodLabel(order.paymentMethod),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
              if (constraints.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [location, const SizedBox(height: 6), payment],
                );
              }
              return Row(
                children: [
                  Expanded(child: location),
                  const SizedBox(width: 8),
                  Flexible(child: payment),
                ],
              );
            },
          ),
          if (order.note != null) ...[
            const SizedBox(height: 9),
            Text(
              'Ghi chú: ${order.note}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          DeliveryInfoWidget(order: order),
          const SizedBox(height: 14),
          DeliveryProgressTimeline(order: order, compact: true),
          const SizedBox(height: 13),
          MapPreviewCard(order: order, onMapTap: onTrackTap, compact: true),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = [
                _OutlinedAction(
                  key: ValueKey('delivering-detail-${order.id}'),
                  icon: Icons.receipt_long_outlined,
                  label: 'Chi tiết',
                  onPressed: onDetailsTap,
                ),
                completed
                    ? _PrimaryAction(
                        key: ValueKey('delivery-review-${order.id}'),
                        icon: Icons.star_outline_rounded,
                        label: 'Đánh giá',
                        onPressed: onReviewTap,
                      )
                    : _OutlinedAction(
                        key: ValueKey('call-shipper-${order.id}'),
                        icon: Icons.call_outlined,
                        label: 'Gọi',
                        onPressed: onContactTap,
                      ),
                _OutlinedAction(
                  key: ValueKey('track-delivery-${order.id}'),
                  icon: Icons.near_me_outlined,
                  label: 'Theo dõi',
                  onPressed: onTrackTap,
                ),
              ];
              if (constraints.maxWidth < 310) {
                return Column(
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0) const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: actions[index]),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) const SizedBox(width: 7),
                    Expanded(child: actions[index]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: deliveryGreen.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        completed ? 'Đã giao' : 'Đang giao',
        style: const TextStyle(
          color: deliveryGreen,
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
            height: 58,
            width: 58,
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

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: FittedBox(child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: deliveryGreen,
        side: const BorderSide(color: Color(0xFFCFEBDD)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: FittedBox(child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      ),
    );
  }
}

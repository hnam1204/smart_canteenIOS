import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../all_orders_controller.dart';
import '../order_model.dart';
import 'order_action_buttons.dart';
import 'order_status_chip.dart';

class OrderDetailBottomSheet extends StatelessWidget {
  const OrderDetailBottomSheet({
    super.key,
    required this.order,
    required this.onCancelTap,
    required this.onTrackTap,
    required this.onQrTap,
    required this.onReviewTap,
    required this.onReorderTap,
  });

  final OrderModel order;
  final VoidCallback onCancelTap;
  final VoidCallback onTrackTap;
  final VoidCallback onQrTap;
  final VoidCallback onReviewTap;
  final VoidCallback onReorderTap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.56,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 11),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chi tiết đơn hàng',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('order-detail-sheet-content'),
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                children: [
                  _DetailHeader(order: order),
                  const SizedBox(height: 13),
                  _DetailCard(
                    title: 'Món đã đặt',
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < order.items.length;
                          index++
                        ) ...[
                          _DetailItem(item: order.items[index]),
                          if (index != order.items.length - 1)
                            const Divider(height: 18, color: AppColors.divider),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  _DetailCard(
                    title: 'Thông tin nhận món',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.storefront_outlined,
                          label: 'Quầy nhận',
                          value: order.pickupCounter,
                        ),
                        const SizedBox(height: 11),
                        _InfoRow(
                          icon: Icons.payment_outlined,
                          label: 'Thanh toán',
                          value:
                              '${order.paymentMethod} · ${paymentStatusLabel(order.paymentStatus)}',
                        ),
                        if (order.note != null) ...[
                          const SizedBox(height: 11),
                          _InfoRow(
                            icon: Icons.sticky_note_2_outlined,
                            label: 'Ghi chú',
                            value: order.note!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  _DetailCard(
                    title: 'Tiến trình đơn hàng',
                    child: OrderTimeline(events: order.timeline),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Tổng cộng',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatOrderCurrency(order.total),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  OrderActionButtons(
                    order: order,
                    onDetailsTap: () {},
                    onCancelTap: onCancelTap,
                    onTrackTap: onTrackTap,
                    onQrTap: onQrTap,
                    onReviewTap: onReviewTap,
                    onReorderTap: onReorderTap,
                    includeDetails: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.events});

  final List<OrderTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          _TimelineRow(event: events[index], last: index == events.length - 1),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4EB), Colors.white],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
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
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AppFoodImage(
            source: item.imageAsset,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          'x${item.quantity}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Text(
          formatOrderCurrency(item.total),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.last});

  final OrderTimelineEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = event.completed ? AppColors.primary : AppColors.divider;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: event.completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!last)
              Container(width: 2, height: 32, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 17),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      color: event.completed
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  event.time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

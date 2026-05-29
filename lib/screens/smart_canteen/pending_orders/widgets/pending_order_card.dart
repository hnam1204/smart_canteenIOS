import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../order_model.dart';
import 'waiting_timer_widget.dart';

class PendingOrderCard extends StatelessWidget {
  const PendingOrderCard({
    super.key,
    required this.order,
    required this.waitingTime,
    required this.onCancelTap,
    required this.onDetailsTap,
    required this.onContactTap,
  });

  final OrderModel order;
  final Duration waitingTime;
  final VoidCallback onCancelTap;
  final VoidCallback onDetailsTap;
  final VoidCallback onContactTap;

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
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
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
              const _PendingChip(),
            ],
          ),
          const SizedBox(height: 13),
          _OrderPreview(order: order),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 16,
                color: AppColors.primary,
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
              Flexible(
                child: Text(
                  paymentMethodLabel(order.paymentMethod),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (order.note != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ghi chú: ${order.note}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 13),
          WaitingTimerWidget(waitingTime: waitingTime),
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
              if (constraints.maxWidth < 310) {
                return Column(
                  children: [
                    _DetailsButton(orderId: order.id, onPressed: onDetailsTap),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CancelButton(
                            orderId: order.id,
                            onPressed: onCancelTap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ContactButton(
                            orderId: order.id,
                            onPressed: onContactTap,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _CancelButton(
                      orderId: order.id,
                      onPressed: onCancelTap,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _ContactButton(
                      orderId: order.id,
                      onPressed: onContactTap,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _DetailsButton(
                      orderId: order.id,
                      onPressed: onDetailsTap,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Text(
        'Chờ xác nhận',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
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
                  color: AppColors.textPrimary,
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

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.orderId, required this.onPressed});

  final String orderId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: ValueKey('cancel-$orderId'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.32)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      ),
      child: const FittedBox(child: Text('Hủy đơn')),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.orderId, required this.onPressed});

  final String orderId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: ValueKey('contact-$orderId'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: Color(0xFFFFD1B0)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      ),
      child: const FittedBox(child: Text('Liên hệ quầy')),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.orderId, required this.onPressed});

  final String orderId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: ValueKey('pending-detail-$orderId'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      ),
      child: const FittedBox(child: Text('Xem chi tiết')),
    );
  }
}

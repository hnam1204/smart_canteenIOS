import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../order_model.dart';
import 'preparation_progress_bar.dart';
import 'preparation_timeline.dart';
import 'preparing_status_banner.dart';

class PreparingOrderCard extends StatelessWidget {
  const PreparingOrderCard({
    super.key,
    required this.order,
    required this.onDetailsTap,
    required this.onTrackTap,
    required this.onContactTap,
    required this.onQrTap,
  });

  final OrderModel order;
  final VoidCallback onDetailsTap;
  final VoidCallback onTrackTap;
  final VoidCallback onContactTap;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final ready = order.status == OrderStatus.readyForPickup;
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
              _PreparingChip(ready: ready),
            ],
          ),
          const SizedBox(height: 13),
          _OrderPreview(order: order),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: preparingBlue,
                size: 16,
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
                  color: AppColors.textSecondary,
                  size: 15,
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
          PreparationProgressBar(order: order),
          const SizedBox(height: 14),
          PreparationTimeline(order: order, compact: true),
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
              final buttons = [
                _SecondaryButton(
                  key: ValueKey('preparing-detail-${order.id}'),
                  icon: Icons.receipt_long_outlined,
                  label: 'Chi tiết',
                  onPressed: onDetailsTap,
                ),
                _SecondaryButton(
                  key: ValueKey('track-${order.id}'),
                  icon: Icons.timeline_rounded,
                  label: 'Theo dõi',
                  onPressed: onTrackTap,
                ),
                ready
                    ? _PrimaryButton(
                        key: ValueKey('preparing-qr-${order.id}'),
                        icon: Icons.qr_code_rounded,
                        label: 'Mã QR',
                        onPressed: onQrTap,
                      )
                    : _SecondaryButton(
                        key: ValueKey('preparing-contact-${order.id}'),
                        icon: Icons.headset_mic_outlined,
                        label: 'Liên hệ',
                        onPressed: onContactTap,
                      ),
              ];
              if (constraints.maxWidth < 310) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: buttons.first),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: buttons[1]),
                        const SizedBox(width: 8),
                        Expanded(child: buttons[2]),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    if (index > 0) const SizedBox(width: 7),
                    Expanded(child: buttons[index]),
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

class _PreparingChip extends StatelessWidget {
  const _PreparingChip({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.success : preparingBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        ready ? 'Sẵn sàng nhận' : 'Đang chuẩn bị',
        style: TextStyle(
          color: color,
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

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
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
        foregroundColor: preparingBlue,
        side: const BorderSide(color: Color(0xFFD5E4FC)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'order_item_tile.dart';

class OrderInfoCard extends StatelessWidget {
  const OrderInfoCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 350;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 15 : 19,
        18,
        compact ? 15 : 19,
        17,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đơn hàng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _OrderTime(
                    label: 'Thời gian đặt món',
                    value: order.placedAt,
                  ),
                ),
                const VerticalDivider(width: 25, color: AppColors.divider),
                Expanded(
                  child: _OrderTime(
                    label: 'Thời gian sẵn sàng',
                    value: order.readyAt,
                    highlighted: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final item in order.items) OrderItemTile(item: item),
          const Divider(height: 23, color: AppColors.divider),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng cộng',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatCurrency(order.total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTime extends StatelessWidget {
  const _OrderTime({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: highlighted
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (highlighted) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

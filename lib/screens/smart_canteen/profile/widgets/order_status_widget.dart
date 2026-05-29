import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../user_model.dart';

class OrderStatusSection extends StatelessWidget {
  const OrderStatusSection({
    super.key,
    required this.statuses,
    required this.onStatusTap,
    required this.onViewAllTap,
  });

  final List<OrderStatusSummary> statuses;
  final ValueChanged<OrderStatusSummary> onStatusTap;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const Text(
              'Đơn hàng của tôi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có đơn hàng',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đơn hàng của tôi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('view-all-orders'),
                onPressed: onViewAllTap,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                label: const Text('Xem tất cả'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final roomy = constraints.maxWidth >= 530;
              if (roomy) {
                return Row(
                  children: [
                    for (final status in statuses)
                      Expanded(
                        child: _StatusItem(
                          status: status,
                          onTap: () => onStatusTap(status),
                        ),
                      ),
                  ],
                );
              }
              return SizedBox(
                height: 80,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (var index = 0; index < statuses.length; index++) ...[
                        SizedBox(
                          width: 75,
                          child: _StatusItem(
                            status: statuses[index],
                            onTap: () => onStatusTap(statuses[index]),
                          ),
                        ),
                        if (index != statuses.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.status, required this.onTap});

  final OrderStatusSummary status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = status.kind == OrderStatusKind.all;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('profile-order-status-${status.kind.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  _iconFor(status.kind),
                  color: highlighted
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 26,
                ),
                if (status.count > 0)
                  Positioned(
                    right: -10,
                    top: -9,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 17,
                        minWidth: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        '${status.count}',
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: highlighted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(OrderStatusKind kind) {
    switch (kind) {
      case OrderStatusKind.all:
        return Icons.shopping_bag_outlined;
      case OrderStatusKind.pending:
        return Icons.wallet_outlined;
      case OrderStatusKind.preparing:
        return Icons.soup_kitchen_outlined;
      case OrderStatusKind.delivering:
        return Icons.delivery_dining_outlined;
      case OrderStatusKind.completed:
        return Icons.fact_check_outlined;
      case OrderStatusKind.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

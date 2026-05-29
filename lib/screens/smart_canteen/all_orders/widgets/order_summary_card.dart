import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../all_orders_controller.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.totalOrders,
    required this.totalSpent,
    required this.processingOrders,
  });

  final int totalOrders;
  final int totalSpent;
  final int processingOrders;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryData(
        icon: Icons.receipt_long_outlined,
        label: 'Tổng đơn',
        value: '$totalOrders',
      ),
      _SummaryData(
        icon: Icons.payments_outlined,
        label: 'Đã chi',
        value: formatOrderCurrency(totalSpent),
      ),
      _SummaryData(
        icon: Icons.local_dining_outlined,
        label: 'Đang xử lý',
        value: '$processingOrders',
      ),
    ];
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F3),
          border: Border.all(color: const Color(0xFFFFE1CB)),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(child: _SummaryItem(data: items[index])),
              if (index != items.length - 1) const SizedBox(width: 5),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(data.icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

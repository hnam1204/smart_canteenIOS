import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivered_status_banner.dart';

class DeliveredActionButtons extends StatelessWidget {
  const DeliveredActionButtons({
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
    final actions = [
      _Action(
        key: ValueKey('delivered-detail-${order.id}'),
        icon: Icons.receipt_long_outlined,
        label: 'Chi tiết',
        onTap: onDetailsTap,
      ),
      _Action(
        key: ValueKey('delivered-review-${order.id}'),
        icon: Icons.star_outline,
        label: order.reviewed ? 'Đã đánh giá' : 'Đánh giá',
        primary: !order.reviewed,
        onTap: onReviewTap,
        isReviewedStyle: order.reviewed,
      ),
      _Action(
        key: ValueKey('reorder-${order.id}'),
        icon: Icons.shopping_cart_checkout_rounded,
        label: 'Mua lại',
        onTap: onReorderTap,
      ),
      _Action(
        key: ValueKey('invoice-${order.id}'),
        icon: Icons.description_outlined,
        label: 'Hóa đơn',
        onTap: onInvoiceTap,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: constraints.maxWidth < 310 ? 2.65 : 3.15,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: actions,
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.isReviewedStyle = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool isReviewedStyle;

  @override
  Widget build(BuildContext context) {
    if (isReviewedStyle) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textTertiary,
          backgroundColor: AppColors.divider.withValues(alpha: 0.5),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 7),
              Text(label),
            ],
          ),
        ),
      );
    }
    if (primary) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.textTertiary,
        ),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 7),
              Text(label),
            ],
          ),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: deliveredGreen,
        disabledForegroundColor: AppColors.textTertiary,
        side: const BorderSide(color: Color(0xFFCFEBDD)),
      ),
      child: FittedBox(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
      ),
    );
  }
}

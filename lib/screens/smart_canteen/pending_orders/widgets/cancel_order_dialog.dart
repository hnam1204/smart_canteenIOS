import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';

class CancelOrderDialog extends StatelessWidget {
  const CancelOrderDialog({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.09),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cancel_outlined,
          color: AppColors.error,
          size: 28,
        ),
      ),
      title: const Text(
        'Hủy đơn hàng?',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Bạn có chắc muốn hủy đơn ${order.id} không?',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Không'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const ValueKey('confirm-cancel-order'),
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Hủy đơn'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

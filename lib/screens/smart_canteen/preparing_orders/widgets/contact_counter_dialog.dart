import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'preparing_status_banner.dart';

class ContactCounterDialog extends StatelessWidget {
  const ContactCounterDialog({
    super.key,
    required this.order,
    required this.onCallTap,
  });

  final OrderModel order;
  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: preparingBlue.withValues(alpha: 0.09),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.headset_mic_outlined, color: preparingBlue),
      ),
      title: const Text(
        'Liên hệ quầy',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            order.pickupCounter,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Hotline hỗ trợ: 1900 1234',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('call-counter-now'),
                onPressed: onCallTap,
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('Gọi ngay'),
                style: FilledButton.styleFrom(backgroundColor: preparingBlue),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

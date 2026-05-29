import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivery_info_widget.dart';
import 'delivery_status_banner.dart';

class ContactShipperDialog extends StatelessWidget {
  const ContactShipperDialog({
    super.key,
    required this.order,
    required this.onCallTap,
    required this.onMessageTap,
  });

  final OrderModel order;
  final VoidCallback onCallTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Liên hệ shipper',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShipperAvatar(seed: order.delivery.avatarSeed, size: 62),
          const SizedBox(height: 10),
          Text(
            order.delivery.shipperName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            order.delivery.phone,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 9),
          Text(
            order.delivery.destination,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: deliveryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('message-shipper'),
                onPressed: onMessageTap,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Nhắn tin'),
                style: OutlinedButton.styleFrom(foregroundColor: deliveryGreen),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('call-shipper-now'),
                onPressed: onCallTap,
                icon: const Icon(Icons.call_outlined, size: 16),
                label: const Text('Gọi'),
                style: FilledButton.styleFrom(backgroundColor: deliveryGreen),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivery_status_banner.dart';

class DeliveryCountdown extends StatelessWidget {
  const DeliveryCountdown({
    super.key,
    required this.remainingTime,
    required this.completed,
  });

  final Duration remainingTime;
  final bool completed;

  String get formatted {
    final minutes = remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : deliveryGreen;
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            completed
                ? 'Đơn đã được giao thành công'
                : 'Dự kiến đến sau $formatted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class DeliveryInfoWidget extends StatelessWidget {
  const DeliveryInfoWidget({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final completed = order.status == OrderStatus.completed;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: deliveryGreenSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ShipperAvatar(seed: order.delivery.avatarSeed),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.delivery.shipperName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.delivery.phone,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!completed)
                Text(
                  order.delivery.remainingDistance,
                  style: const TextStyle(
                    color: deliveryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          DeliveryCountdown(
            remainingTime: order.remainingTime,
            completed: completed,
          ),
        ],
      ),
    );
  }
}

class ShipperAvatar extends StatelessWidget {
  const ShipperAvatar({super.key, required this.seed, this.size = 40});

  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) => _ShipperAvatar(seed: seed, size: size);
}

class _ShipperAvatar extends StatelessWidget {
  const _ShipperAvatar({required this.seed, this.size = 40});

  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    const colors = [
      [Color(0xFFD9F7E4), Color(0xFFF0FDF4)],
      [Color(0xFFFFE5D1), Color(0xFFFFF4EA)],
      [Color(0xFFDCEAFE), Color(0xFFF0F6FF)],
    ];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors[seed % colors.length]),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.58,
        color: const Color(0xFF477361),
      ),
    );
  }
}

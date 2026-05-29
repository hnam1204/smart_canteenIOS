import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'preparing_status_banner.dart';

class PreparationCountdown extends StatelessWidget {
  const PreparationCountdown({
    super.key,
    required this.remainingTime,
    required this.ready,
  });

  final Duration remainingTime;
  final bool ready;

  String get formatted {
    final minutes = remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ready ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
          color: ready ? AppColors.success : preparingBlue,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            ready
                ? 'Món đã sẵn sàng để nhận'
                : 'Dự kiến sẵn sàng sau $formatted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ready ? AppColors.success : preparingBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class PreparationProgressBar extends StatelessWidget {
  const PreparationProgressBar({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final ready = order.status == OrderStatus.readyForPickup;
    final elapsed =
        order.totalPreparationTime.inSeconds - order.remainingTime.inSeconds;
    final progress = ready
        ? 1.0
        : (elapsed / order.totalPreparationTime.inSeconds).clamp(0.08, 0.98);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: ready
            ? AppColors.success.withValues(alpha: 0.07)
            : preparingBlueSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                preparationStageLabel(order.stage),
                style: TextStyle(
                  color: ready ? AppColors.success : preparingBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: ready ? AppColors.success : preparingBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              color: ready ? AppColors.success : preparingBlue,
              backgroundColor: (ready ? AppColors.success : preparingBlue)
                  .withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 9),
          PreparationCountdown(
            remainingTime: order.remainingTime,
            ready: ready,
          ),
        ],
      ),
    );
  }
}

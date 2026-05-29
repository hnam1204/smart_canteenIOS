import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivery_status_banner.dart';

class DeliveryProgressTimeline extends StatelessWidget {
  const DeliveryProgressTimeline({
    super.key,
    required this.order,
    this.compact = false,
  });

  final OrderModel order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Đã nhận đơn',
      'Đang chuẩn bị',
      'Đã lấy món',
      'Đang giao',
      'Đã giao',
    ];
    final current = switch (order.stage) {
      DeliveryStage.received => 0,
      DeliveryStage.preparing => 1,
      DeliveryStage.pickedUp => 2,
      DeliveryStage.delivering => 3,
      DeliveryStage.completed => 4,
    };
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: index == 0
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: index <= current
                                  ? deliveryGreen
                                  : AppColors.divider,
                            ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: index == current ? 19 : 15,
                      width: index == current ? 19 : 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= current
                            ? deliveryGreen
                            : AppColors.surface,
                        border: Border.all(
                          color: index <= current
                              ? deliveryGreen
                              : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: index < current
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 9,
                            )
                          : null,
                    ),
                    Expanded(
                      child: index == labels.length - 1
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: index < current
                                  ? deliveryGreen
                                  : AppColors.divider,
                            ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  labels[index],
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: index == current
                        ? deliveryGreen
                        : AppColors.textSecondary,
                    fontWeight: index == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: compact ? 9 : 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'preparing_status_banner.dart';

class PreparationTimeline extends StatelessWidget {
  const PreparationTimeline({
    super.key,
    required this.order,
    this.compact = false,
  });

  final OrderModel order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Đặt hàng', PreparationStage.received),
      ('Đã xác nhận', PreparationStage.cooking),
      ('Đang chuẩn bị', PreparationStage.packing),
      ('Sẵn sàng nhận', PreparationStage.ready),
    ];
    final current = switch (order.stage) {
      PreparationStage.received => 0,
      PreparationStage.cooking => 2,
      PreparationStage.packing || PreparationStage.almostReady => 2,
      PreparationStage.ready => 3,
    };
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
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
                                  ? preparingBlue
                                  : AppColors.divider,
                            ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: index == current ? 19 : 16,
                      width: index == current ? 19 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= current
                            ? preparingBlue
                            : AppColors.surface,
                        border: Border.all(
                          color: index <= current
                              ? preparingBlue
                              : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: index < current
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 10,
                            )
                          : null,
                    ),
                    Expanded(
                      child: index == steps.length - 1
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: index < current
                                  ? preparingBlue
                                  : AppColors.divider,
                            ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  steps[index].$1,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: compact ? 9.5 : 10.5,
                    color: index == current
                        ? preparingBlue
                        : AppColors.textSecondary,
                    fontWeight: index == current
                        ? FontWeight.w700
                        : FontWeight.w500,
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

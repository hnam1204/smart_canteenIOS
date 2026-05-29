import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class PaymentCountdownWidget extends StatelessWidget {
  const PaymentCountdownWidget({
    super.key,
    required this.secondsRemaining,
    required this.onRefresh,
  });

  final int secondsRemaining;
  final VoidCallback onRefresh;

  String get _timeText {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'QR hết hạn sau $_timeText',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('refresh-vietqr'),
            tooltip: 'Làm mới QR',
            visualDensity: VisualDensity.compact,
            onPressed: onRefresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

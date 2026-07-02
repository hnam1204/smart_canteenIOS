import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class PaymentCountdownWidget extends StatelessWidget {
  const PaymentCountdownWidget({
    super.key,
    required this.secondsRemaining,
    required this.expired,
    required this.onRefresh,
  });

  final int secondsRemaining;
  final bool expired;
  final VoidCallback onRefresh;

  String get _timeText {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (expired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.timer_off_outlined,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'QR đã hết hạn',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('create-new-vietqr'),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Tạo mã QR mới'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      );
    }

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

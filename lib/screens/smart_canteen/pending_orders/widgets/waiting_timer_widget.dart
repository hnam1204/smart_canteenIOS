import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class WaitingTimerWidget extends StatelessWidget {
  const WaitingTimerWidget({super.key, required this.waitingTime});

  final Duration waitingTime;

  bool get delayed => waitingTime >= const Duration(minutes: 10);

  String get formattedTime {
    final minutes = waitingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (waitingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final accent = delayed ? AppColors.error : AppColors.primary;
    final progress = (waitingTime.inSeconds / 600).clamp(0.03, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 15, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Đã chờ $formattedTime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (delayed) ...[
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Lâu hơn dự kiến',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

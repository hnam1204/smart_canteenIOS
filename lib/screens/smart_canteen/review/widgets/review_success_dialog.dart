import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class ReviewSuccessDialog extends StatelessWidget {
  const ReviewSuccessDialog({
    super.key,
    required this.onHomeTap,
    required this.onHistoryTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 25, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 35,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cảm ơn đánh giá của bạn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Ý kiến của bạn giúp Smart Canteen phục vụ tốt hơn mỗi ngày.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 21),
            FilledButton(
              key: const ValueKey('review-home-button'),
              onPressed: onHomeTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 49),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Về trang chủ'),
            ),
            const SizedBox(height: 9),
            OutlinedButton(
              key: const ValueKey('review-history-button'),
              onPressed: onHistoryTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 49),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Xem lịch sử đơn'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

const preparingBlue = Color(0xFF2563EB);
const preparingBlueSoft = Color(0xFFEFF6FF);

class PreparingStatusBanner extends StatelessWidget {
  const PreparingStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.97, end: 1),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 3, 18, 13),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: preparingBlueSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E8FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: preparingBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.soup_kitchen_rounded,
                color: preparingBlue,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhà bếp đang chuẩn bị món',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Đơn hàng của bạn đang được chế biến, vui lòng chờ trong ít phút',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

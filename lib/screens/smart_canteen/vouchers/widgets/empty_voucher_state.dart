import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class EmptyVoucherState extends StatelessWidget {
  const EmptyVoucherState({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.primary,
              size: 52,
            ),
            const SizedBox(height: 13),
            const Text(
              'Bạn chưa có ưu đãi nào',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            const Text(
              'Các mã giảm giá và ưu đãi sẽ hiển thị tại đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 17),
            FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Khám phá món ăn'),
            ),
          ],
        ),
      ),
    );
  }
}

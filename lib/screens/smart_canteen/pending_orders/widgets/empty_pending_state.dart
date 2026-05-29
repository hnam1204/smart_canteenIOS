import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class EmptyPendingState extends StatelessWidget {
  const EmptyPendingState({super.key, required this.onOrderNowTap});

  final VoidCallback onOrderNowTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 86,
              width: 86,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có đơn hàng chờ xác nhận',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các đơn mới đặt sẽ hiển thị ở đây',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('pending-order-now'),
              onPressed: onOrderNowTap,
              icon: const Icon(Icons.restaurant_menu_rounded, size: 19),
              label: const Text('Đặt món ngay'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

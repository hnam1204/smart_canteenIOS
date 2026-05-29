import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import 'preparing_status_banner.dart';

class EmptyPreparingState extends StatelessWidget {
  const EmptyPreparingState({super.key, required this.onOrderNowTap});

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
                color: preparingBlueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.soup_kitchen_outlined,
                color: preparingBlue,
                size: 43,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có đơn hàng đang chuẩn bị',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các đơn đã được xác nhận sẽ hiển thị ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('preparing-order-now'),
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

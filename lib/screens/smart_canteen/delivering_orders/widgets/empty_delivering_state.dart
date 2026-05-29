import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import 'delivery_status_banner.dart';

class EmptyDeliveringState extends StatelessWidget {
  const EmptyDeliveringState({super.key, required this.onOrderNowTap});

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
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: deliveryGreenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_outlined,
                size: 44,
                color: deliveryGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có đơn hàng đang giao',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các đơn đang được giao sẽ hiển thị ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('delivering-order-now'),
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

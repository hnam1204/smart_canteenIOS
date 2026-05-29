import 'package:flutter/material.dart';

import '../../../core/widgets/custom_bottom_nav_bar.dart';

class CanteenBottomNavBar extends StatelessWidget {
  const CanteenBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.cartCount,
    required this.onTap,
    this.notificationCount = 0,
  });

  final int selectedIndex;
  final int cartCount;
  final int notificationCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavBar(
      selectedIndex: selectedIndex,
      onTap: onTap,
      items: [
        const CustomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Trang chủ',
        ),
        const CustomNavItem(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Menu',
        ),
        CustomNavItem(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart_rounded,
          badge: cartCount > 0 ? '$cartCount' : null,
          label: 'Giỏ hàng',
        ),
        CustomNavItem(
          icon: Icons.notifications_none_rounded,
          activeIcon: Icons.notifications_rounded,
          badge: notificationCount > 0 ? '$notificationCount' : null,
          label: 'Thông báo',
        ),
        const CustomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Tài khoản',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.notificationCount,
    required this.onSettingsTap,
    required this.onNotificationsTap,
  });

  final int notificationCount;
  final VoidCallback onSettingsTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      child: SizedBox(
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Tài khoản',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderButton(
                    tooltip: 'Cài đặt tài khoản',
                    icon: Icons.settings_outlined,
                    onPressed: onSettingsTap,
                  ),
                  const SizedBox(width: 7),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeaderButton(
                        tooltip: 'Thông báo',
                        icon: Icons.notifications_none_rounded,
                        onPressed: onNotificationsTap,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: -1,
                          top: -3,
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 17,
                              minWidth: 17,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

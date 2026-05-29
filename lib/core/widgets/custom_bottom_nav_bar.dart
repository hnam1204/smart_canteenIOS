import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  }) : assert(items.length > 1);

  static const double contentHeight = 72;

  final int selectedIndex;
  final List<CustomNavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.07),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        minimum: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          height: contentHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: items[index]._withState(
                      selected: index == selectedIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomNavItem extends StatelessWidget {
  const CustomNavItem({
    super.key,
    required this.label,
    this.icon,
    this.activeIcon,
    this.assetPath,
    this.badge,
    this.selected = false,
    this.onTap,
  }) : assert(icon != null || assetPath != null);

  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final String? assetPath;
  final String? badge;
  final bool selected;
  final VoidCallback? onTap;

  CustomNavItem _withState({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CustomNavItem(
      label: label,
      icon: icon,
      activeIcon: activeIcon,
      assetPath: assetPath,
      badge: badge,
      selected: selected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? AppColors.primary
        : (dark ? AppColors.textSecondaryDark : AppColors.textSecondary);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.06 : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: 42,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFF3E9),
                                    Color(0xFFFFE9D8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: assetPath == null
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 210),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.86,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Icon(
                                  selected ? (activeIcon ?? icon) : icon,
                                  key: ValueKey(selected),
                                  size: 23,
                                  color: color,
                                ),
                              )
                            : Image.asset(
                                assetPath!,
                                height: 23,
                                width: 23,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -5,
                      child: AnimatedBadge(label: badge),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 16,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      offset: selected ? Offset.zero : const Offset(0, 0.04),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          height: 1.1,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        child: Text(label, maxLines: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends AnimatedBottomNavBar {
  const CustomBottomNavBar({
    super.key,
    required super.selectedIndex,
    required super.items,
    required super.onTap,
  });
}

typedef BottomNavItem = CustomNavItem;

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) =>
      AnimatedBadge(label: itemCount > 0 ? '$itemCount' : null);
}

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) =>
      AnimatedBadge(label: unreadCount > 0 ? '$unreadCount' : null);
}

class AnimatedBadge extends StatelessWidget {
  const AnimatedBadge({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: label == null
          ? const SizedBox.shrink(key: ValueKey('empty-badge'))
          : Container(
              key: ValueKey(label),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

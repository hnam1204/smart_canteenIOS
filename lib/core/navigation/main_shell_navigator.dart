import 'package:flutter/material.dart';

import '../../screens/smart_canteen/main_shell_screen.dart';

/// Utility for navigating within [MainShellScreen] from anywhere in the app.
/// Provides methods to jump to specific tabs (0-4) from nested screens.
class MainShellNavigator {
  MainShellNavigator._();

  /// Jump to a specific tab in [MainShellScreen].
  ///
  /// Tab indices:
  /// - 0: Home (SmartCanteenHomeScreen)
  /// - 1: Menu (MenuScreen)
  /// - 2: Cart (CartScreen)
  /// - 3: Notifications (NotificationScreen)
  /// - 4: Profile (ProfileScreen)
  ///
  /// Uses [MainShellController] InheritedWidget for reliable lookup.
  /// If [context] is not inside a [MainShellScreen], this method does nothing.
  static void jumpToTab(BuildContext context, int tabIndex) {
    assert(tabIndex >= 0 && tabIndex < 5, 'Tab index must be between 0-4');
    MainShellController.maybeOf(context)?.jumpToTab(tabIndex);
  }

  /// Convenience helpers.
  static void jumpToHome(BuildContext context) => jumpToTab(context, 0);
  static void jumpToMenu(BuildContext context) => jumpToTab(context, 1);
  static void jumpToCart(BuildContext context) => jumpToTab(context, 2);
  static void jumpToNotifications(BuildContext context) =>
      jumpToTab(context, 3);
  static void jumpToProfile(BuildContext context) => jumpToTab(context, 4);
}

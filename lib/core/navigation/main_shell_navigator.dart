import 'package:flutter/material.dart';

import '../../screens/smart_canteen/main_shell_screen.dart';

/// Utility for navigating to MainShellScreen tabs from anywhere in the app.
class MainShellNavigator {
  MainShellNavigator._();

  /// Navigate to MainShellScreen at a specific tab.
  ///
  /// Tab indices:
  /// - 0: Home (SmartCanteenHomeScreen)
  /// - 1: Menu (MenuScreen)
  /// - 2: Cart (CartScreen)
  /// - 3: Notifications (NotificationScreen)
  /// - 4: Profile (ProfileScreen)
  static Future<void> jumpToTab(BuildContext context, int tabIndex) async {
    assert(tabIndex >= 0 && tabIndex < 5, 'Tab index must be between 0-4');

    if (tabIndex < 0 || tabIndex >= 5 || !context.mounted) {
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => MainShellScreen(initialIndex: tabIndex),
      ),
      (route) => false,
    );
  }
}

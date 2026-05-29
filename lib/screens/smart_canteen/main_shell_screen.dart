import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'notifications/notification_screen.dart';
import 'profile/profile_screen.dart';
import 'smart_canteen_home_screen.dart' show SmartCanteenHomeScreen;
import 'widgets/canteen_bottom_nav_bar.dart';

/// InheritedWidget that exposes tab-switching to any descendant widget.
///
/// Tab indices:
/// - 0: Home
/// - 1: Menu
/// - 2: Cart
/// - 3: Notifications
/// - 4: Profile
class MainShellController extends InheritedWidget {
  const MainShellController({
    super.key,
    required this.jumpToTab,
    required super.child,
  });

  final void Function(int index) jumpToTab;

  /// Returns the nearest [MainShellController], or null if not inside a shell.
  static MainShellController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellController>();

  @override
  bool updateShouldNotify(MainShellController oldWidget) =>
      jumpToTab != oldWidget.jumpToTab;
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex < 5);

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _selectedIndex;
  late final List<Widget?> _pages;
  late final CartProvider _cartProvider;
  late final NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = List<Widget?>.filled(5, null);
    _cartProvider = CartProvider()..addListener(_onBadgeChanged);
    _notificationProvider = NotificationProvider()
      ..addListener(_onBadgeChanged);
    _pages[_selectedIndex] = _buildPage(_selectedIndex);
    _cartProvider.bindCurrentUser();
    _notificationProvider.bindCurrentUser();
  }

  @override
  void dispose() {
    _cartProvider.removeListener(_onBadgeChanged);
    _notificationProvider.removeListener(_onBadgeChanged);
    _cartProvider.dispose();
    _notificationProvider.dispose();
    super.dispose();
  }

  void _onBadgeChanged() {
    if (mounted) setState(() {});
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _pages[index] ??= _buildPage(index);
      _selectedIndex = index;
    });
  }

  // Public method to allow external screens to jump to specific tabs
  void selectTabPublic(int index) {
    _selectTab(index);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return SmartCanteenHomeScreen(
          embedded: true,
          onTabSelected: _selectTab,
        );
      case 1:
        return MenuScreen(embedded: true, onTabSelected: _selectTab);
      case 2:
        return CartScreen(embedded: true, onTabSelected: _selectTab);
      case 3:
        return NotificationScreen(
          cartCount: _cartProvider.itemCount,
          embedded: true,
          onTabSelected: _selectTab,
        );
      case 4:
        return ProfileScreen(
          cartCount: _cartProvider.itemCount,
          embedded: true,
          onTabSelected: _selectTab,
        );
      default:
        throw ArgumentError.value(index, 'index', 'Unsupported tab index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _cartProvider.itemCount;
    final notificationCount = _notificationProvider.unreadCount;
    // Wrap with MainShellController so any descendant can call jumpToTab
    // without needing to access the private _MainShellScreenState type.
    return MainShellController(
      jumpToTab: _selectTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _selectedIndex,
          children: List<Widget>.generate(
            _pages.length,
            (index) => _pages[index] ?? const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: CanteenBottomNavBar(
          selectedIndex: _selectedIndex,
          cartCount: cartCount,
          notificationCount: notificationCount,
          onTap: _selectTab,
        ),
      ),
    );
  }
}

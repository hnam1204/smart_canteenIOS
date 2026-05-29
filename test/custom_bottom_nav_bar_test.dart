import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/core/widgets/custom_bottom_nav_bar.dart';

void main() {
  testWidgets('custom navigation stays stable on compact widths', (
    tester,
  ) async {
    final selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);

    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (context, index, _) {
              return CustomBottomNavBar(
                selectedIndex: index,
                onTap: (value) => selected.value = value,
                items: const [
                  CustomNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
                  CustomNavItem(icon: Icons.restaurant_menu, label: 'Menu'),
                  CustomNavItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Giỏ hàng',
                    badge: '12',
                  ),
                  CustomNavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Thông báo',
                  ),
                  CustomNavItem(icon: Icons.person_outline, label: 'Tài khoản'),
                ],
              );
            },
          ),
        ),
      ),
    );

    final initialSize = tester.getSize(find.byType(CustomBottomNavBar));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Giỏ hàng'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(CustomBottomNavBar)), initialSize);
    expect(tester.takeException(), isNull);
  });
}

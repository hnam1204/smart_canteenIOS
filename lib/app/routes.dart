import 'package:flutter/material.dart';
import '../core/navigation/app_page_transition.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String menu = '/menu';
  static const String foodDetail = '/food-detail';
  static const String cart = '/cart';
  static const String payment = '/payment';
  static const String qr = '/qr';
  static const String orderHistory = '/order-history';
  static const String review = '/review';
  static const String notification = '/notification';
  static const String account = '/account';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      home: (context) => const HomeScreen(),
      // Add other routes here as screens are implemented
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = getRoutes()[settings.name];
    if (builder == null) return null;
    return AppPageTransition<void>(builder: builder);
  }
}

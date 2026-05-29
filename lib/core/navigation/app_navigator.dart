import 'package:flutter/material.dart';

import 'app_page_transition.dart';

class AppNavigator {
  AppNavigator._();

  static Future<T?> push<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return Navigator.of(
      context,
    ).push<T>(AppPageTransition<T>(builder: builder));
  }

  static Future<T?> replace<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return Navigator.of(
      context,
    ).pushReplacement<T, Object?>(AppPageTransition<T>(builder: builder));
  }

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    final navigator = Navigator.of(context);
    if (replace) {
      return navigator.pushReplacementNamed<T, Object?>(
        routeName,
        arguments: arguments,
      );
    }
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil<T>(routeName, predicate, arguments: arguments);
  }
}

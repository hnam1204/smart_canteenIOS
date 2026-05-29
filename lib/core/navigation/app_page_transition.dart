import 'package:flutter/material.dart';

class AppPageTransition<T> extends PageRouteBuilder<T> {
  AppPageTransition({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final enter = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final exit = CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: enter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0.012),
                end: Offset.zero,
              ).animate(enter),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.992, end: 1).animate(enter),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0.96).animate(exit),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
}

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF944D);
  static const Color primaryDark = Color(0xFFE85A00);
  static const Color primarySoft = Color(0xFFFFF1E7);
  static const Color accent = Color(0xFFFF7A1A);

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF0F4FA);
  static const Color field = Color(0xFFF3F5F8);
  static const Color divider = Color(0xFFE7EBF2);
  static const Color backgroundDark = Color(0xFF091321);
  static const Color surfaceDark = Color(0xFF111F32);
  static const Color surfaceSoftDark = Color(0xFF172840);
  static const Color fieldDark = Color(0xFF16263A);
  static const Color dividerDark = Color(0xFF273B54);

  static const Color textPrimary = Color(0xFF141B2D);
  static const Color textSecondary = Color(0xFF707787);
  static const Color textTertiary = Color(0xFF9AA2B1);
  static const Color textPrimaryDark = Color(0xFFF4F7FC);
  static const Color textSecondaryDark = Color(0xFFB2BCD0);
  static const Color textTertiaryDark = Color(0xFF8491A8);

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = primary;
  static const Color white = Colors.white;
  static const Color black = Color(0xFF111827);

  static const Color cardBackground = surface;
  static const Color creamBackground = background;
  static const Color textDarkBlue = textPrimary;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF5A00), Color(0xFFFF6B00), Color(0xFFFF9847)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF102A43).withValues(alpha: 0.055),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF102A43).withValues(alpha: 0.025),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

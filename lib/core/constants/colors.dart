import 'package:flutter/material.dart';

class DynamicColor extends Color {
  final Color Function() resolver;
  const DynamicColor(super.defaultValue, this.resolver);

  @override
  // ignore: deprecated_member_use
  int get value => resolver().value;
}

class AppColors {
  static bool isDark = false;

  static Color _resolvePrimary() => const Color(0xFFFF6B00);
  static Color _resolvePrimaryLight() => const Color(0xFFFF944D);
  static Color _resolvePrimaryDark() => const Color(0xFFE85A00);
  static Color _resolvePrimarySoft() => isDark ? const Color(0xFF2E241F) : const Color(0xFFFFF1E7);
  static Color _resolveAccent() => const Color(0xFFFF7A1A);

  static Color _resolveBackground() => isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);
  static Color _resolveSurface() => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color _resolveSurfaceSoft() => isDark ? const Color(0xFF26354A) : const Color(0xFFF0F4FA);
  static Color _resolveField() => isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F5F8);
  static Color _resolveDivider() => isDark ? const Color(0xFF334155) : const Color(0xFFE7EBF2);

  static Color _resolveTextPrimary() => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF141B2D);
  static Color _resolveTextSecondary() => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF707787);
  static Color _resolveTextTertiary() => isDark ? const Color(0xFF8491A8) : const Color(0xFF9AA2B1);

  static const Color primary = DynamicColor(0xFFFF6B00, _resolvePrimary);
  static const Color primaryLight = DynamicColor(0xFFFF944D, _resolvePrimaryLight);
  static const Color primaryDark = DynamicColor(0xFFE85A00, _resolvePrimaryDark);
  static const Color primarySoft = DynamicColor(0xFFFFF1E7, _resolvePrimarySoft);
  static const Color accent = DynamicColor(0xFFFF7A1A, _resolveAccent);

  static const Color background = DynamicColor(0xFFF5F7FB, _resolveBackground);
  static const Color surface = DynamicColor(0xFFFFFFFF, _resolveSurface);
  static const Color surfaceSoft = DynamicColor(0xFFF0F4FA, _resolveSurfaceSoft);
  static const Color field = DynamicColor(0xFFF3F5F8, _resolveField);
  static const Color divider = DynamicColor(0xFFE7EBF2, _resolveDivider);

  static const Color backgroundDark = Color(0xFF091321);
  static const Color surfaceDark = Color(0xFF111F32);
  static const Color surfaceSoftDark = Color(0xFF172840);
  static const Color fieldDark = Color(0xFF16263A);
  static const Color dividerDark = Color(0xFF273B54);

  static const Color textPrimary = DynamicColor(0xFF141B2D, _resolveTextPrimary);
  static const Color textSecondary = DynamicColor(0xFF707787, _resolveTextSecondary);
  static const Color textTertiary = DynamicColor(0xFF9AA2B1, _resolveTextTertiary);

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
      color: isDark ? const Color(0x33000000) : const Color(0xFF102A43).withValues(alpha: 0.055),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: isDark ? const Color(0x1A000000) : const Color(0xFF102A43).withValues(alpha: 0.025),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

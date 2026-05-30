import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  final SharedPreferences _prefs;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider(this._prefs) {
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    AppColors.isDark = _isDarkMode;
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    AppColors.isDark = value;
    await _prefs.setBool(_themeKey, value);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { system, light, dark, black }

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme';

  AppTheme _theme = AppTheme.system;

  AppTheme get theme => _theme;

  ThemeMode get themeMode {
    switch (_theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.black:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  void setTheme(AppTheme theme) async {
    if (_theme == theme) return;

    _theme = theme;
    await _saveTheme(theme);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themePreferenceKey);
    if (themeString != null) {
      _theme = AppTheme.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => AppTheme.system,
      );
    }
    // No need to call notifyListeners() here, as the theme is set before the UI is built.
  }

  Future<void> _saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, theme.toString());
  }
}

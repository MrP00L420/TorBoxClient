
import 'package:flutter/material.dart';

enum AppTheme {
  system,
  light,
  dark,
  black,
}

class ThemeProvider with ChangeNotifier {
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
      default:
        return ThemeMode.system;
    }
  }

  void setTheme(AppTheme theme) {
    _theme = theme;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:TBox/storage_service.dart';

enum AppTheme { system, light, dark, black }

class ThemeProvider with ChangeNotifier {
  final _storageService = StorageService();
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

  Future<void> loadTheme() async {
    final themeString = await _storageService.getTheme();
    if (themeString != null) {
      try {
        _theme = AppTheme.values.firstWhere((e) => e.toString() == themeString);
      } catch (e) {
        // Fallback to system theme if the stored value is invalid
        _theme = AppTheme.system;
      }
    }
    // No need to notify listeners, this is called before runApp
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_theme == theme) return;

    _theme = theme;
    await _storageService.saveTheme(theme.toString());
    notifyListeners();
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // --- Keys ---
  static const _apiKey = 'api_key';
  static const _appLockKey = 'app_lock';
  static const _themeKey = 'app_theme';

  // --- Storage Instance with Hardened Config ---
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      // Correct, valid, and secure option for this library version
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // --- API Key Methods ---
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKey);
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKey);
  }

  // --- App Lock Methods ---
  Future<void> setAppLock(bool isEnabled) async {
    await _secureStorage.write(key: _appLockKey, value: isEnabled.toString());
  }

  Future<bool> isAppLockEnabled() async {
    final value = await _secureStorage.read(key: _appLockKey);
    return value == 'true';
  }

  // --- Theme Methods ---
  Future<void> saveTheme(String theme) async {
    await _secureStorage.write(key: _themeKey, value: theme);
  }

  Future<String?> getTheme() async {
    return await _secureStorage.read(key: _themeKey);
  }
}

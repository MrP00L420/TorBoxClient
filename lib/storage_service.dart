import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _apiKey = 'api_key';
  static const _appLockKey = 'app_lock';
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKey);
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKey);
  }

  Future<void> setAppLock(bool isEnabled) async {
    await _secureStorage.write(key: _appLockKey, value: isEnabled.toString());
  }

  Future<bool> isAppLockEnabled() async {
    final value = await _secureStorage.read(key: _appLockKey);
    return value == 'true';
  }
}

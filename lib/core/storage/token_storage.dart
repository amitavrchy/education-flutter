import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Keychain (iOS) / Keystore-backed (Android) storage for the session.
/// Tokens never go into plain SharedPreferences.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  Future<String?> readUserJson() => _storage.read(key: StorageKeys.user);

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required String userJson,
  }) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    await _storage.write(key: StorageKeys.user, value: userJson);
  }

  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.user);
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens live in Keychain/Keystore only — never memory-only or SharedPreferences
/// (Section 4D).
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _hiveKey = 'hive_aes_key';

  /// 32-byte AES key for the encrypted Hive cache (HiveAesCipher), generated
  /// once and kept in the Keychain/Keystore (Section 4D).
  Future<List<int>> getOrCreateHiveKey() async {
    final existing = await _storage.read(key: _hiveKey);
    if (existing != null) return base64Decode(existing);
    final rng = Random.secure();
    final key = List<int>.generate(32, (_) => rng.nextInt(256));
    await _storage.write(key: _hiveKey, value: base64Encode(key));
    return key;
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  static const _onboardingKey = 'onboarding_seen';
  Future<bool> get onboardingSeen async =>
      (await _storage.read(key: _onboardingKey)) == 'true';
  Future<void> setOnboardingSeen() =>
      _storage.write(key: _onboardingKey, value: 'true');
}

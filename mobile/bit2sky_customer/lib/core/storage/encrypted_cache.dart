import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'secure_storage.dart';

/// AES-encrypted, TTL'd offline cache (Section 4D). Any PHI cached offline must
/// use HiveAesCipher; entries carry an expiry (≤24h for PHI) and are cleared on logout.
class EncryptedCache {
  EncryptedCache._(this._box);

  static const _boxName = 'bit2sky_secure_cache';
  final Box<String> _box;

  static Future<EncryptedCache> open(SecureStorageService storage) async {
    await Hive.initFlutter();
    final key = await storage.getOrCreateHiveKey();
    final box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
    return EncryptedCache._(box);
  }

  /// Returns the cached JSON value for [key] if present and not expired.
  dynamic read(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    final entry = jsonDecode(raw) as Map<String, dynamic>;
    final expiresAt = entry['expiresAt'] as int? ?? 0;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      _box.delete(key);
      return null;
    }
    return entry['value'];
  }

  Future<void> write(String key, dynamic value, Duration ttl) async {
    await _box.put(
      key,
      jsonEncode({
        'value': value,
        'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
      }),
    );
  }

  /// Clears all cached data — called on logout.
  Future<void> clear() => _box.clear();
}

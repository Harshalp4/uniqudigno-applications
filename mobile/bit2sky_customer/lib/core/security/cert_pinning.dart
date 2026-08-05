import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Certificate pinning (Section 4D). Validates the leaf certificate's SHA-256
/// fingerprint against the configured allowlist. When no pins are configured
/// (local/dev builds) the platform's default trust chain is used.
class CertPinning {
  CertPinning._();

  /// Leaf + backup-CA SHA-256 fingerprints (base64), injected at build time:
  ///   --dart-define=CERT_PINS=`b64sha256,b64sha256`
  static final List<String> _pins = const String.fromEnvironment('CERT_PINS')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static bool get isEnabled => _pins.isNotEmpty;

  /// Called from the HttpClient badCertificateCallback. Returns true to accept.
  static bool isTrusted(X509Certificate cert) {
    if (!isEnabled) return false; // no pins ⇒ defer to default chain validation
    final fingerprint = base64.encode(sha256.convert(cert.der).bytes);
    return _pins.contains(fingerprint);
  }
}

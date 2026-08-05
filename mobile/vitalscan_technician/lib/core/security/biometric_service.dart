import 'package:local_auth/local_auth.dart';

/// Biometric gate before PHI access (Section 4D — required before viewing/
/// downloading reports, family vault, AI chat).
class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Returns true when the user authenticates (or no biometrics are available,
  /// in which case the OS prompts for device PIN/passcode as the fallback).
  Future<bool> authenticate(
      {String reason = 'Authenticate to view your health data'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // PIN/passcode fallback, never bypass
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      // On a device without any auth configured we fail closed (deny access).
      return false;
    }
  }
}

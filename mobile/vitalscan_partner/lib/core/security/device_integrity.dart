import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Root / jailbreak detection (Section 4D). On a compromised device the app
/// disables PHI screens and biometric auth, and runs in limited mode.
class DeviceIntegrityService {
  Future<bool> get isCompromised async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (_) {
      return false; // detection unavailable ⇒ don't hard-block the user
    }
  }
}

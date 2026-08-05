import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/device_integrity.dart';

final deviceIntegrityProvider = Provider((ref) => DeviceIntegrityService());

/// True when the device is rooted/jailbroken — PHI screens are blocked.
final deviceCompromisedProvider = FutureProvider<bool>((ref) async {
  return ref.read(deviceIntegrityProvider).isCompromised;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/branding_config.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final brandingProvider = FutureProvider<BrandingConfig>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/config/branding');
    return BrandingConfig.fromJson(data);
  } catch (_) {
    return const BrandingConfig(
        appName: 'VitalScan Partner',
        tagline: 'Grow with VitalScan',
        primaryColor: '#00897B');
  }
});

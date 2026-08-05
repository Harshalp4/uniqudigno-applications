import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/brand_palette.dart';
import 'app_providers.dart';

/// D1 — the runtime brand ramp, recomputed whenever `/config/branding`
/// resolves. Falls back to the static teal tokens until (or unless) the
/// branding call succeeds, so first paint never flashes an off-brand color.
final brandPaletteProvider = Provider<BrandPalette>((ref) {
  final branding = ref.watch(brandingProvider).asData?.value;
  return branding == null
      ? BrandPalette.fallback
      : BrandPalette.fromHex(branding.primaryColor,
          accentHex: branding.secondaryColor,
          navAccentHex: branding.navAccentColor);
});

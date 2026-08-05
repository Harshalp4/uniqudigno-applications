import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/content_models.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/ecg_placeholder.dart';
import '../../../widgets/pressable.dart';
import 'section_common.dart';

/// D2 §3 (reference parity) — large pastel category tiles with an offer chip
/// overlapping the tile bottom and the label below. Tile background colors,
/// labels, offers, and deep links all come from the section payload; a tile
/// without `offerText` shows no chip (no invented discounts).
class CategoryTilesSection extends ConsumerWidget {
  final HomeSection section;
  const CategoryTilesSection({super.key, required this.section});

  static Color _bg(Map<String, dynamic> tile, Color fallback) {
    final hex = tile['bg']?.toString();
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return AppColors.fromHex(hex);
    } catch (_) {
      return fallback;
    }
  }

  /// Soften a pastel far toward white for a muted, professional base (not a
  /// saturated slab).
  static Color _soften(Color c) => Color.lerp(c, Colors.white, 0.55)!;

  // Tile art precedence: payload `imageUrl` (real photo, full-bleed cover) →
  // animated ECG placeholder while it loads / on error / when the API sends
  // no image. The placeholder inherits the tile's pastel + brand accent so
  // "no image yet" still looks intentional.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = configItems(section.config, 'tiles');
    if (tiles.isEmpty) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty) ...[
            SectionHeader(title: section.title, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.s12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, tile) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Pressable(
                    onTap: () =>
                        navigateDeepLink(context, tile['deepLink']?.toString()),
                    child: Column(
                      children: [
                        // Illustration tile with the offer chip riding its
                        // bottom edge (reference pattern).
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Photo tile when the payload carries an image;
                            // gradient + icon plate otherwise (and as the
                            // fallback while a photo loads or fails).
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r20),
                              child: SizedBox(
                                height: 68,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  alignment: Alignment.center,
                                  children: [
                                    // Animated branded placeholder: visible
                                    // until a real photo covers it, and the
                                    // permanent art when the API sends none.
                                    EcgPlaceholder(
                                      base: _soften(_bg(tile, palette.tint)),
                                      accent: palette.primary,
                                    ),
                                    if ((tile['imageUrl']?.toString() ?? '')
                                        .isNotEmpty)
                                      _FadeInNetworkImage(
                                          url: tile['imageUrl'].toString()),
                                    // Offer pill parked at the tile's bottom.
                                    if ((tile['offerText']?.toString() ?? '')
                                        .isNotEmpty)
                                      Positioned(
                                        bottom: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.s8,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.r100),
                                            boxShadow: AppShadows.shadow1,
                                          ),
                                          child: Text(
                                            tile['offerText'].toString(),
                                            maxLines: 1,
                                            style: AppTextStyles.caption.copyWith(
                                                color: palette.primaryDark,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        // Fixed 2-line box so the three tiles align regardless
                        // of label length.
                        SizedBox(
                          height: 30,
                          child: Text(
                            tile['label']?.toString() ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionMed
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-bleed network photo that fades in over the placeholder once decoded;
/// renders nothing on error so the animated placeholder stays.
class _FadeInNetworkImage extends StatelessWidget {
  final String url;
  const _FadeInNetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSyncLoaded) => wasSyncLoaded
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            ),
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

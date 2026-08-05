import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../models/content_models.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/pressable.dart';
import 'section_common.dart';

/// Shared horizontal rail for the payload-driven browse sections (D2 §8-§10).
/// Two card treatments, chosen per item by the payload:
///  - `imageUrl` present → editorial photo card with a brand scrim and the
///    label/price/CTA overlaid (reference "health concerns" pattern);
///  - otherwise → two-tone gradient tile with the icon on a raised white
///    plate, label/price/CTA centered below.
/// Everything (labels, images, colors, prices, links) comes from the DB;
/// a failed image falls back to the gradient tile — never a broken card.
class ThemedRailSection extends ConsumerWidget {
  final HomeSection section;

  /// Adds the "Book Now" affordance (organ rail styling).
  final bool showBookNow;

  const ThemedRailSection({
    super.key,
    required this.section,
    this.showBookNow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = configItems(section.config);
    if (items.isEmpty) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);
    final hasPhotos = !showBookNow &&
        items.any((i) => (i['imageUrl']?.toString() ?? '').isNotEmpty);
    final hasCaptionRows = !hasPhotos &&
        (showBookNow ||
            items.any((i) => (i['fromPricePaise'] as num?) != null));


    // Photo cards carry their text inside; tiles stack label(+price+CTA) below.
    final railHeight = hasPhotos ? 176.0 : (hasCaptionRows ? 168.0 : 96.0);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: SectionHeader(
                dense: true,
                  title: section.title, padding: EdgeInsets.zero),
            ),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.s12),
              itemBuilder: (context, i) {
                final item = items[i];
                final imageUrl = item['imageUrl']?.toString() ?? '';
                return Pressable(
                  onTap: () =>
                      navigateDeepLink(context, item['deepLink']?.toString()),
                  // Product-card rails (Book Now) keep the card structure and
                  // show the photo in the header; simple rails use the full
                  // scrim photo card.
                  child: imageUrl.isNotEmpty && !showBookNow
                      ? _PhotoCard(
                          item: item,
                          palette: palette,
                          showBookNow: showBookNow,
                          height: railHeight,
                        )
                      : _GradientTile(
                          item: item,
                          palette: palette,
                          showBookNow: showBookNow,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Descriptive agent for CDN-hosted content art (Wikimedia's bot policy
/// rejects the default Dart agent under load).
const _imageUserAgent = 'Bit2skyCustomer/1.0 (+https://bit2sky.app)';

Color _parseHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    return AppColors.fromHex(hex);
  } catch (_) {
    return fallback;
  }
}

/// Slightly deeper shade of [c] for the gradient end (depth without a second
/// payload color).
Color _deepen(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - 0.07).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation + 0.10).clamp(0.0, 1.0))
      .toColor();
}

/// Editorial photo card: image + brand scrim + overlaid label/price/CTA.
class _PhotoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final BrandPalette palette;
  final bool showBookNow;
  final double height;

  const _PhotoCard({
    required this.item,
    required this.palette,
    required this.showBookNow,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fromPaise = item['fromPricePaise'] as num?;
    final bg = _parseHex(item['bg']?.toString(), palette.tint);
    return SizedBox(
      width: 140,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient underneath doubles as the loading/error state.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bg, _deepen(bg)],
                ),
              ),
            ),
            Image.network(
              item['imageUrl'].toString(),
              headers: const {'User-Agent': _imageUserAgent},
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            // Scrim so the overlaid text always reads (reference pattern).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1.0],
                  colors: [
                    Colors.transparent,
                    palette.primaryDark.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item['label']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                  ),
                  if (fromPaise != null && fromPaise > 0)
                    Text(
                      'from ₹${(fromPaise / 100).round()}',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70),
                    ),
                  if (showBookNow) ...[
                    const SizedBox(height: AppSpacing.s6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70),
                        borderRadius: BorderRadius.circular(AppRadius.r100),
                      ),
                      child: Text(
                        'Book Now',
                        style: AppTextStyles.label
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product card (reference "book by organ" pattern): white card holding an
/// illustration block (gradient + oversized watermark icon + raised icon
/// plate), then name, from-price, and a tinted Book Now pill.
class _GradientTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final BrandPalette palette;
  final bool showBookNow;

  const _GradientTile({
    required this.item,
    required this.palette,
    required this.showBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final fromPaise = item['fromPricePaise'] as num?;
    final bg = _parseHex(item['bg']?.toString(), palette.tint);
    final bg2 = _parseHex(item['bg2']?.toString(), _deepen(bg));
    final icon = materialIcon(item['icon']?.toString() ?? '');

    final imageUrl = item['imageUrl']?.toString() ?? '';
    final illustration = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, bg2],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // "Spotlight stage" backdrop: soft radial glow + halo rings so
            // the artwork sits on a lit surface instead of a flat slab.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.95,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
            if (imageUrl.isNotEmpty)
              // Payload-driven header art; `"fit":"contain"` floats
              // transparent illustrations on the gradient, photos fill.
              Padding(
                padding: item['fit'] == 'contain'
                    ? const EdgeInsets.all(AppSpacing.s6)
                    : EdgeInsets.zero,
                child: Image.network(
                  imageUrl,
                  headers: const {'User-Agent': _imageUserAgent},
                  fit: item['fit'] == 'contain'
                      ? BoxFit.contain
                      : BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              )
            else ...[
              // Oversized watermark gives the block illustrative depth; the
              // gentle pulse keeps the rail feeling alive without asset work.
              Positioned(
                right: -14,
                bottom: -18,
                child: _BreathingIcon(
                  icon: icon,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.shadow1,
                  ),
                  child: Icon(icon, color: palette.primary, size: 19),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!showBookNow) {
      // Simple rails (no CTA): illustration + centered label.
      return SizedBox(
        width: 112,
        child: Column(
          children: [
            illustration,
            const SizedBox(height: AppSpacing.s6),
            Text(
              item['label']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.h4,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 128,
      padding: const EdgeInsets.all(AppSpacing.s8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(height: AppSpacing.s6),
          Text(
            item['label']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.h4,
          ),
          if (fromPaise != null && fromPaise > 0)
            Text(
              'from ₹${(fromPaise / 100).round()}',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: palette.primary),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.tint,
              borderRadius: BorderRadius.circular(AppRadius.r100),
            ),
            child: Text(
              'Book Now',
              style:
                  AppTextStyles.label.copyWith(color: palette.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}


/// Slow scale "breathing" (1.0 → 1.08, ~1.6s) for decorative watermarks.
class _BreathingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  const _BreathingIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.08).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}

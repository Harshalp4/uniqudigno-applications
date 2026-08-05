import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/brand_palette.dart';
import 'pressable.dart';

/// THE package card (home density redesign §2.7) — the single card layout for
/// every package rail on home ("Popular packages" AND "Last viewed"; never
/// maintain a second layout). 150 wide, ≤150 tall, "offer ticket" look:
///   diagonal discount ribbon across the top-right corner · brand-tinted blob
///   backdrop · 2-line title · meta row ("N Tests" + Details) · price block
///   anchored above a full-bleed 34px gradient CTA with a periodic sheen sweep.
/// Motion: press scale via [Pressable]; the CTA sheen repeats every ~2.6s and
/// is disabled entirely under reduce-motion.
class PackageCardX extends StatefulWidget {
  final String title;
  final int? testCount;
  final num price;
  final num mrp;
  final BrandPalette palette;
  final VoidCallback onTap;
  final VoidCallback? onDetails;

  /// Hero tag (package id) for the card → detail transition. Null disables.
  final String? heroTag;

  static const double width = 150;
  static const double height = 150;

  const PackageCardX({
    super.key,
    required this.title,
    required this.price,
    required this.mrp,
    required this.palette,
    required this.onTap,
    this.testCount,
    this.onDetails,
    this.heroTag,
  });

  /// Rails size themselves off this: card height grows with the text scale
  /// (clamped) so large-type users never hit a RenderFlex overflow.
  static double heightFor(BuildContext context) =>
      height * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

  @override
  State<PackageCardX> createState() => _PackageCardXState();
}

class _PackageCardXState extends State<PackageCardX>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  int get _off => widget.mrp <= 0
      ? 0
      : (((widget.mrp - widget.price) / widget.mrp) * 100).round();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce-motion: no ambient animation at all.
    if (MediaQuery.of(context).disableAnimations) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

    final card = Container(
      width: PackageCardX.width,
      constraints: BoxConstraints(minHeight: PackageCardX.height * scale),
      decoration: BoxDecoration(
        // Soft brand wash: white at the title, gently tinted toward the CTA.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            Color.alphaBlend(
                palette.primary.withValues(alpha: 0.07), AppColors.surface),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppShadows.hairline),
        boxShadow: AppShadows.card,
      ),
      // Foreground column + decorative layers all clip to the card shape.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Stack(
          children: [
            // Brand-tinted blob peeking in from the bottom-left.
            Positioned(
              left: -34,
              bottom: 6,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s8, AppSpacing.s8, AppSpacing.s8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed 2-line box so every card in a rail lines up;
                      // right inset keeps clear of the corner ribbon.
                      SizedBox(
                        height: 36 * scale,
                        child: Padding(
                          padding: EdgeInsets.only(right: _off > 0 ? 26 : 0),
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitleCompact,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Row(
                        children: [
                          if (widget.testCount != null &&
                              widget.testCount! > 0) ...[
                            Icon(Icons.science_outlined,
                                size: 12, color: AppColors.moneyAccentDark),
                            const SizedBox(width: AppSpacing.s4),
                            Text(
                              '${widget.testCount} Tests',
                              style: AppTextStyles.captionMed.copyWith(
                                  color: AppColors.moneyAccentDark),
                            ),
                          ],
                          const Spacer(),
                          if (widget.onDetails != null)
                            Pressable(
                              onTap: widget.onDetails,
                              child: Semantics(
                                button: true,
                                label: 'Package details',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: palette.primary
                                        .withValues(alpha: 0.10),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.r100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Details',
                                        style: AppTextStyles.captionMed
                                            .copyWith(color: palette.primary),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          size: 12, color: palette.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Price block sits directly above the CTA for a tight
                // "cost → act" read.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s8, 0, AppSpacing.s8, AppSpacing.s6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${widget.price.round()}',
                          style: AppTextStyles.priceCompact
                              .copyWith(color: palette.primary)),
                      if (widget.mrp > widget.price) ...[
                        const SizedBox(width: AppSpacing.s6),
                        Flexible(
                          child: Text(
                            '₹${widget.mrp.round()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.priceStrike,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _SheenCta(
                  label: 'BOOK NOW',
                  semanticsLabel: 'Book ${widget.title}',
                  palette: palette,
                  sheen: _sheen,
                ),
              ],
            ),
            // Diagonal discount ribbon across the top-right corner.
            if (_off > 0)
              Positioned(
                top: 12,
                right: -30,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 104,
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFFFF9A3D),
                        Color(0xFFFF6B35),
                      ]),
                    ),
                    child: Text(
                      '$_off% OFF',
                      style: AppTextStyles.captionMed.copyWith(
                        color: Colors.white,
                        fontSize: 9.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final pressable = Pressable(onTap: widget.onTap, child: card);
    if (widget.heroTag == null) return pressable;
    return Hero(
      tag: widget.heroTag!,
      child: Material(type: MaterialType.transparency, child: pressable),
    );
  }
}

/// Full-bleed gradient CTA bar with a periodic diagonal sheen sweep. The sweep
/// occupies the first 40% of each [sheen] cycle, then rests — noticeable
/// without being busy. Static when the controller is stopped (reduce-motion).
class _SheenCta extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final BrandPalette palette;
  final Animation<double> sheen;

  const _SheenCta({
    required this.label,
    required this.semanticsLabel,
    required this.palette,
    required this.sheen,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        height: 34,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.primary, palette.primaryDark],
                ),
              ),
            ),
            // Sheen: a soft white stripe sweeping left → right.
            AnimatedBuilder(
              animation: sheen,
              builder: (context, _) {
                final t = Curves.easeInOut
                    .transform((sheen.value / 0.4).clamp(0.0, 1.0));
                if (t <= 0.0 || t >= 1.0) return const SizedBox.shrink();
                return FractionalTranslation(
                  translation: Offset(-1.2 + 2.4 * t, 0),
                  child: Transform.rotate(
                    angle: 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: AppTextStyles.ctaCompact
                          .copyWith(color: AppColors.textInverse)),
                  const SizedBox(width: AppSpacing.s4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.textInverse),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

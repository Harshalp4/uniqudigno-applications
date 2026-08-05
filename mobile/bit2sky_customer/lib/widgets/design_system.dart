import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/brand_palette.dart';
import 'pressable.dart';

/// D1 — core merchandising components (Healthians-parity, premium execution).
///
/// Rules encoded here so screens can't drift:
/// - Price rows always frame the discount as savings (₹final bold, ₹mrp
///   struck through, "X% OFF" badge in the money accent).
/// - Amber ([AppColors.moneyAccent]) appears ONLY on money surfaces.
/// - Brand color comes from the injected [BrandPalette] (DB-driven), with
///   [BrandPalette.fallback] as the compile-time default.
/// - One CTA style per card; soft single-source shadows; 4pt spacing grid.

// ─────────────────────────────────────────────────────────────── PriceRow ──

/// `₹1143  ₹4971  [UPTO 76% OFF]` — the canonical price row.
class PriceRow extends StatelessWidget {
  final num price;
  final num mrp;

  /// large = detail screens / package cards; small = list rows.
  final bool large;
  final BrandPalette palette;

  const PriceRow({
    super.key,
    required this.price,
    required this.mrp,
    this.large = false,
    this.palette = BrandPalette.fallback,
  });

  int get _off => mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '₹${price.round()}',
          style: (large ? AppTextStyles.priceLarge : AppTextStyles.h4)
              .copyWith(color: palette.primary),
        ),
        if (mrp > price) ...[
          const SizedBox(width: AppSpacing.s6),
          Flexible(
            child: Text(
              '₹${mrp.round()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.priceStrikethrough,
            ),
          ),
          if (_off > 0) ...[
            const SizedBox(width: AppSpacing.s6),
            MoneyBadge(text: 'UPTO $_off% OFF'),
          ],
        ],
      ],
    );
  }
}

/// Money-accent badge — offers, wallet credits, incentives. Never used for
/// health status (that's [AppColors.successGreen]/[AppColors.errorRed]).
class MoneyBadge extends StatelessWidget {
  final String text;
  const MoneyBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.moneyAccentLight,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: AppColors.moneyAccentDark),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── OfferStrip ──

/// Slim full-width offer strip ("Get up to 70% OFF on all bookings").
/// Money surface → amber family; text comes from the DB, never hardcoded.
class OfferStrip extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const OfferStrip({
    super.key,
    required this.text,
    this.icon = Icons.local_offer_outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strip = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.moneyAccentLight,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.moneyAccentDark),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.moneyAccentDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.moneyAccentDark),
        ],
      ),
    );
    return onTap == null
        ? strip
        : Pressable(scale: 0.99, onTap: onTap, child: strip);
  }
}

// ─────────────────────────────────────────────────────────── FilterChips ──

/// Single-select horizontal filter chips (package/category rails).
class FilterChipsRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final BrandPalette palette;
  final EdgeInsets padding;

  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.palette = BrandPalette.fallback,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, i) {
          final label = options[i];
          final on = label == selected;
          return Pressable(
            scale: 0.96,
            onTap: () => onSelect(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? palette.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r100),
                border: Border.all(
                    color: on ? palette.primary : AppColors.borderDefault),
              ),
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(
                    color: on ? AppColors.textInverse : AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── TrustBadges ──

/// Accreditation / trust chips row (NABL, CAP, ISO … from DB config).
/// Neutral surfaces — trust is not a money surface, so no amber here.
class TrustBadgeRow extends StatelessWidget {
  final List<String> badges;
  final BrandPalette palette;

  const TrustBadgeRow({
    super.key,
    required this.badges,
    this.palette = BrandPalette.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink(); // no dead UI
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final badge in badges)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12, vertical: AppSpacing.s6),
            decoration: BoxDecoration(
              color: palette.tint,
              borderRadius: BorderRadius.circular(AppRadius.r100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 14, color: palette.primary),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  badge,
                  style:
                      AppTextStyles.label.copyWith(color: palette.primaryDark),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────── Skeleton loader ──

/// Skeleton block for loading rails (D-track: skeletons over spinners).
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final BrandPalette palette;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.r8,
    this.palette = BrandPalette.fallback,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.palette.tintStrong,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── Pro internal-screen kit ──
//
// Shared building blocks for the elevated internal screens (category landing,
// catalogue, detail, cart, orders…). One source of truth so every screen
// carries the same gradient hero, trust strip, savings badge and quick-add.

/// Brand-gradient hero header with a soft icon watermark, a back button, an
/// optional trailing action and an optional trust strip. Replaces flat plate
/// app bars on internal screens.
class AppGradientHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? watermark;
  final BrandPalette palette;
  final Widget? trailing;
  final List<(IconData, String)> trust;
  final bool showBack;

  const AppGradientHero({
    super.key,
    required this.title,
    required this.palette,
    this.subtitle,
    this.watermark,
    this.trailing,
    this.trust = const [],
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: AppShadows.shadow2,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (watermark != null)
              Positioned(
                right: -8,
                top: 6,
                child: Icon(watermark,
                    size: 116, color: Colors.white.withValues(alpha: 0.10)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s8, AppSpacing.s4, AppSpacing.s16, AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        Pressable(
                          // After a cold start the screen can be the only
                          // route on the stack — back must still lead home.
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.s8),
                            child: Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                          ),
                        )
                      else
                        const SizedBox(width: AppSpacing.s8),
                      const Spacer(),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                        if (trust.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s12),
                          TrustStrip(items: trust),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent white pills of trust signals, for use inside [AppGradientHero].
class TrustStrip extends StatelessWidget {
  final List<(IconData, String)> items;
  const TrustStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final (icon, label) in items)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.r100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pill "+ Add" action used on cards and list rows.
class AddPill extends StatelessWidget {
  final VoidCallback onTap;
  final BrandPalette palette;
  final String label;
  const AddPill(
      {super.key, required this.onTap, required this.palette, this.label = 'Add'});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.tint,
          borderRadius: BorderRadius.circular(AppRadius.r100),
          border: Border.all(color: palette.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: palette.primary),
            const SizedBox(width: 2),
            Text(label,
                style: AppTextStyles.label.copyWith(
                    color: palette.primary, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// Off-white app background for the elevated internal screens.
const kProScreenBg = Color(0xFFF4F6F9);

/// Standard elevated white card decoration for the pro screens.
BoxDecoration proCardDecoration({double radius = AppRadius.r16}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppShadows.shadow1,
    );

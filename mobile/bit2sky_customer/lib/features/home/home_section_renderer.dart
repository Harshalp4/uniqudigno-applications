import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/account_models.dart';
import '../../models/catalogue_models.dart';
import '../../models/content_models.dart';
import '../../models/misc_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/booking_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/misc_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/buttons.dart';
import 'sections/articles_rail_section.dart';
import 'sections/category_tiles_section.dart';
import 'sections/package_carousel_section.dart';
import 'sections/mid_cards_section.dart';
import 'sections/payload_banner_section.dart';
import 'sections/refer_earn_section.dart';
import 'sections/section_common.dart';
import 'sections/themed_rail_section.dart';
import 'sections/trust_block_section.dart';
import '../../widgets/components.dart';

/// Renders a single home section by its DB-driven [HomeSection.sectionType]
/// (Section 8 — all titles/configs/visibility from DB).
class HomeSectionRenderer extends ConsumerWidget {
  final HomeSection section;
  const HomeSectionRenderer({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Normalise so DB enum names ("Banner") and camelCase fallbacks both match.
    switch (section.sectionType.toLowerCase()) {
      case 'banner':
        return const _BannerSection();
      case 'quickactions':
        return _ServicesSection(
          title: section.title.isEmpty ? 'Our Services' : section.title,
        );
      case 'activebooking':
        return _ActiveBookingSection(
          title: section.title.isEmpty ? 'Active Booking' : section.title,
        );
      case 'healthscore':
        return _HealthScoreCard(
          title: section.title.isEmpty ? 'Health Score' : section.title,
        );
      case 'populartests':
        return _PackageCards(
          title: section.title.isEmpty ? 'Popular Tests' : section.title,
        );
      case 'featuredpackages':
        return PackageCarouselSection(section: section);
      case 'categorygrid':
        return CategoryTilesSection(section: section);
      case 'prescriptionupload':
        // v3 payloads carry a `cards` pair (reference-style mid cards); older
        // payloads with title+cta render the slim banner.
        return section.config['cards'] is List
            ? MidCardsSection(section: section)
            : PayloadBannerSection(
                section: section,
                icon: Icons.upload_file_outlined,
              );
      case 'custompackagebanner':
        return PayloadBannerSection(
          section: section,
          icon: Icons.tune_rounded,
        );
      case 'personaplans':
      case 'concernrail':
      case 'lifestylerail':
        return ThemedRailSection(section: section);
      case 'organrail':
        return ThemedRailSection(section: section, showBookNow: true);
      case 'trustblock':
        return TrustBlockSection(section: section);
      case 'referearn':
        return ReferEarnSection(section: section);
      case 'articles':
        return ArticlesRailSection(section: section);
      case 'recommended':
        return _RecommendedSection(
          title: section.title.isEmpty ? 'Recommended for You' : section.title,
        );
      case 'familyhealth':
        return _FamilyHealthSection(
          title: section.title.isEmpty ? 'Family Health' : section.title,
        );
      case 'offers':
        return _OffersSection(
          title: section.title.isEmpty ? 'Offers' : section.title,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Auto-advancing hero banner carousel, driven by /banners (DB).
/// Redesign §2.8: 16:7 aspect, animated bar-dot indicator, autoplay every 4s
/// gated to actual visibility (no off-screen timers), paused on user
/// interaction and resumed after 6s idle.
class _BannerSection extends ConsumerStatefulWidget {
  const _BannerSection();

  @override
  ConsumerState<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends ConsumerState<_BannerSection> {
  final _controller = PageController();
  Timer? _timer;
  Timer? _resume;
  int _index = 0;
  bool _visible = false;
  int _count = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _resume?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    if (!_visible || _count <= 1 || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _count;
      _controller.animateToPage(
        next,
        duration: AppMotion.of(context, const Duration(milliseconds: 400)),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
  }

  /// User touched the carousel: pause, resume after 6s idle.
  void _onInteraction() {
    _pause();
    _resume?.cancel();
    _resume = Timer(const Duration(seconds: 6), _play);
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref
        .watch(bannersProvider)
        .maybeWhen(data: (b) => b, orElse: () => const <HomeBanner>[]);
    if (banners.isEmpty) return const SizedBox.shrink();
    _count = banners.length;

    return VisibilityDetector(
      key: const Key('home-banner-carousel'),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.5;
        if (visible == _visible) return;
        _visible = visible;
        visible ? _play() : _pause();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHPad,
          AppSpacing.s16,
          AppSpacing.screenHPad,
          0,
        ),
        child: Column(
          children: [
            Listener(
              onPointerDown: (_) => _onInteraction(),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: banners.length,
                  itemBuilder: (_, i) => _BannerCard(banner: banners[i]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.titleToContent),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.base),
                  curve: AppMotion.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? ref.watch(brandPaletteProvider).primary
                        : AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends ConsumerWidget {
  final HomeBanner banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: Container(
        decoration: BoxDecoration(gradient: palette.headerGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1080,
                fadeInDuration: AppMotion.base,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -0.35),
                  end: const Alignment(1, 0.35),
                  colors: [
                    palette.primaryDark.withValues(alpha: 0.92),
                    palette.primary.withValues(alpha: 0.40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(
                        color: Colors.white, fontSize: 16),
                  ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      banner.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyTight.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.titleToContent),
                  PillButton(
                    label: banner.ctaLabel ?? 'Book Now',
                    foreground: palette.primary,
                    onPressed: () => _navigate(context, banner.deepLink),
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

/// Prototype `.section-title` — 17px / 700.
TextStyle get _titleStyle =>
    AppTextStyles.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w700);

/// "Our Services" — a 4-column grid of white cards with DB-driven icon names.
class _ServicesSection extends ConsumerWidget {
  final String title;
  const _ServicesSection({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref
        .watch(quickActionsProvider)
        .maybeWhen(data: (a) => a, orElse: () => <QuickAction>[]);
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Text(title, style: _titleStyle),
          ),
          LayoutBuilder(
            builder: (context, c) {
              const perRow = 4;
              const gap = 8.0;
              final usableWidth = c.maxWidth - (perRow - 1) * gap;
              final tileW = usableWidth <= 0 ? 0.0 : usableWidth / perRow;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final a in actions)
                    SizedBox(
                      width: tileW,
                      child: _ServiceTile(
                        label: a.label,
                        iconValue: a.iconUrl,
                        onTap: () => _navigate(context, a.deepLink),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  final String label;
  final String iconValue;
  final VoidCallback onTap;
  const _ServiceTile({
    required this.label,
    required this.iconValue,
    required this.onTap,
  });

  bool get _isMaterialIconName => RegExp(r'^[a-z0-9_]+$').hasMatch(iconValue);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isMaterialIconName
                  ? Icon(
                      materialIcon(iconValue),
                      color: palette.primary,
                      size: 21,
                    )
                  : Text(iconValue, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active booking card — real data from the user's in-progress booking.
/// Renders nothing (section hidden) for guests or when there's no active order.
class _ActiveBookingSection extends ConsumerWidget {
  final String title;
  const _ActiveBookingSection({required this.title});

  static const _steps = [
    'Booked',
    'Confirmed',
    'On the way',
    'Collected',
    'Report',
  ];

  String _statusLine(String status) => switch (status) {
    'Confirmed' => 'Booking confirmed',
    'TechnicianAssigned' => 'Technician on the way',
    'SampleCollected' => 'Sample collected',
    'InLab' => 'Sample in the lab',
    'ReportReady' => 'Report ready',
    _ => status,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref
        .watch(activeBookingProvider)
        .maybeWhen(data: (b) => b, orElse: () => null);
    // No active booking (or guest) → hide the whole section.
    if (booking == null) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Text(title, style: _titleStyle),
          ),
          GestureDetector(
            onTap: () => context.push('/reports'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -0.6),
                  end: const Alignment(1, 0.6),
                  colors: [palette.tint, AppColors.surface],
                ),
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border(
                  left: BorderSide(color: palette.primary, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.title,
                              style: AppTextStyles.h4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Booking #${booking.bookingNumber}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(AppRadius.r100),
                        ),
                        child: Text(
                          'In Progress',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _StepTracker(steps: _steps, current: booking.currentStep),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    _statusLine(booking.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTracker extends ConsumerWidget {
  final List<String> steps;
  final int current;
  const _StepTracker({required this.steps, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _dot(i, palette.primary),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 3,
                color: i < current
                    ? palette.primary
                    : AppColors.borderDefault,
              ),
            ),
        ],
      ],
    );
  }

  Widget _dot(int i, Color primary) {
    final done = i < current;
    final active = i == current;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: (done || active) ? primary : AppColors.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(
          color: (done || active) ? primary : AppColors.borderStrong,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
    );
  }
}

/// Teal gradient health-score card — real score from /health/score.
/// Hidden for guests or users with no score yet (a fake score would mislead).
class _HealthScoreCard extends ConsumerWidget {
  final String title;
  const _HealthScoreCard({required this.title});

  static String _band(int s) => s >= 80
      ? 'Excellent'
      : s >= 60
      ? 'Good Health'
      : s >= 40
      ? 'Fair'
      : 'Needs attention';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref
        .watch(healthScoreProvider)
        .maybeWhen(data: (s) => s, orElse: () => null);
    if (score == null) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Text(title, style: _titleStyle),
          ),
          GestureDetector(
            onTap: () => context.push('/health'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                gradient: palette.headerGradient,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '/100',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _band(score),
                          style: AppTextStyles.h4.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your latest reports.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View full report',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A package card view-model (mapped from a DB [Package] or the offline fallback).
class _Pkg {
  final String name;
  final int price;
  final int mrp;
  final String meta;
  final String? reportIn;
  final String emoji;

  /// Catalogue slug of the underlying test (when the card is built from a
  /// DB test) — used to deep-link to `/tests/:slug`. Null for offline
  /// fallback items, which route to the catalogue list instead.
  final String? slug;
  const _Pkg(
    this.name,
    this.price,
    this.mrp,
    this.meta, {
    this.reportIn,
    this.emoji = '📦',
    this.slug,
  });
}

const _fallbackPackages = [
  _Pkg('Full Body Basic', 599, 2499, '58 tests', emoji: '🫀'),
  _Pkg('Diabetes Care', 799, 2999, '22 tests', emoji: '🩸'),
  _Pkg('Heart Risk Profile', 1199, 3999, '34 tests', emoji: '❤️'),
  _Pkg("Women's Wellness", 899, 3499, '47 tests', emoji: '🌸'),
  _Pkg('Senior Citizen', 1499, 5999, '72 tests', emoji: '👴'),
];

/// Popular Packages — a horizontal rail from /packages (DB), with offline fallback.
class _PackageCards extends ConsumerWidget {
  final String title;
  const _PackageCards({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pkgs = ref
        .watch(packagesProvider)
        .maybeWhen(data: (p) => p, orElse: () => const <Package>[]);
    final items = pkgs.isNotEmpty
        ? pkgs
              .take(8)
              .map(
                (p) => _Pkg(
                  p.name,
                  p.price.round(),
                  p.mrp.round(),
                  '${p.testCount} tests',
                ),
              )
              .toList()
        : _fallbackPackages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s12,
          ),
          child: _MiniHeader(
            title: title,
            action: 'See all',
            onTap: () => context.push('/packages'),
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (_, i) {
              final p = items[i];
              return SizedBox(
                width: 220,
                child: GestureDetector(
                  // No /packages/:slug detail route exists yet; land on the
                  // packages catalogue rather than the tests list.
                  onTap: () => context.push('/packages'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      border: Border.all(color: AppColors.borderDefault),
                      boxShadow: AppShadows.shadow1,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: ref.watch(brandPaletteProvider).tint,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.r8,
                                ),
                              ),
                              child: Text(
                                p.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: AppTextStyles.h4,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.meta,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${p.price}',
                              style: AppTextStyles.priceLarge.copyWith(
                                color: ref.watch(brandPaletteProvider).primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s6),
                            Text(
                              '₹${p.mrp}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textDisabled,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recommended for You — vertical test cards with +Add, from /tests (DB) + fallback.
class _RecommendedSection extends ConsumerWidget {
  final String title;
  const _RecommendedSection({required this.title});

  static const _fallback = [
    _Pkg(
      'CBC (Complete Blood Count)',
      299,
      599,
      '18 parameters',
      reportIn: '6h',
    ),
    _Pkg('Thyroid Profile Total', 349, 699, '3 parameters', reportIn: '12h'),
    _Pkg('HbA1c', 249, 499, '1 parameter', reportIn: '6h'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref
        .watch(recommendedTestsProvider)
        .maybeWhen(data: (t) => t, orElse: () => const <Test>[]);
    final items = tests.isNotEmpty
        ? tests
              .take(4)
              .map(
                (t) => _Pkg(
                  t.name,
                  t.price.round(),
                  t.mrp.round(),
                  '${t.parameterCount} parameters',
                  reportIn: t.reportTimeText,
                  slug: t.slug,
                ),
              )
              .toList()
        : _fallback;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Text(title, style: _titleStyle),
          ),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: _RecoCard(item: t),
            ),
        ],
      ),
    );
  }
}

class _RecoCard extends StatelessWidget {
  final _Pkg item;
  const _RecoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final off = item.mrp > 0
        ? (100 * (item.mrp - item.price) / item.mrp).round()
        : 0;
    // DB-backed tests open their own detail screen; offline fallback items
    // (no slug) fall back to the catalogue list.
    final target = (item.slug != null && item.slug!.isNotEmpty)
        ? '/tests/${item.slug}'
        : '/tests';
    return GestureDetector(
      onTap: () => context.push(target),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.meta,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.reportIn != null && item.reportIn!.isNotEmpty)
                        _MiniReportTag(text: item.reportIn!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Text('₹${item.price}', style: AppTextStyles.priceLarge),
                      const SizedBox(width: AppSpacing.s6),
                      Flexible(
                        child: Text(
                          '₹${item.mrp}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textDisabled,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (off > 0) StatusBadge.discount('$off% OFF'),
                const SizedBox(height: AppSpacing.s12),
                _MiniAddButton(onTap: () => context.push(target)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniReportTag extends ConsumerWidget {
  final String text;
  const _MiniReportTag({required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final label = text.startsWith('Report') ? text : 'Report in $text';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.tint,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniAddButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _MiniAddButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r8),
          border: Border.all(color: palette.primary, width: 1.3),
        ),
        child: Text(
          '+ Add',
          style: AppTextStyles.button.copyWith(color: palette.primary),
        ),
      ),
    );
  }
}

/// Family Health — member avatars from /users/me/family (DB) + an add tile.
class _FamilyHealthSection extends ConsumerWidget {
  final String title;
  const _FamilyHealthSection({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref
        .watch(familyProvider)
        .maybeWhen(data: (m) => m, orElse: () => const <FamilyMember>[]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniHeader(
            title: title,
            action: 'Manage',
            onTap: () => context.push('/family'),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final m in members)
                  _FamilyAvatar(name: m.name, relation: m.relationship),
                _AddFamilyTile(onTap: () => context.push('/family')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyAvatar extends ConsumerWidget {
  final String name;
  final String relation;
  const _FamilyAvatar({required this.name, required this.relation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: palette.tint,
            child: Text(
              initial,
              style: AppTextStyles.h4.copyWith(color: palette.primary),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 60,
            child: Text(
              relation,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFamilyTile extends ConsumerWidget {
  final VoidCallback onTap;
  const _AddFamilyTile({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.primary, width: 1.5),
            ),
            child: Icon(Icons.add, color: palette.primary),
          ),
          const SizedBox(height: 6),
          Text(
            'Add',
            style: AppTextStyles.caption.copyWith(color: palette.primary),
          ),
        ],
      ),
    );
  }
}

/// Offers — active cashback/coupon strip from /cashback/active-offers (DB) + fallback.
class _OffersSection extends ConsumerWidget {
  final String title;
  const _OffersSection({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref
        .watch(cashbackOffersProvider)
        .maybeWhen(data: (o) => o, orElse: () => const <CashbackOffer>[]);
    // No real offers → hide the section (don't fabricate a "HEALTH20" coupon).
    if (offers.isEmpty) return const SizedBox.shrink();

    final o = offers.first;
    final headline = o.title;
    final sub = o.description ?? 'Limited-period offer';
    final reward = o.rewardType == 'Percentage'
        ? '${o.rewardValue.round()}% back'
        : '₹${o.rewardValue.round()} back';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Text(title, style: _titleStyle),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              // .coupon-strip — warm orange gradient.
              gradient: const LinearGradient(
                begin: Alignment(-1, -0.35),
                end: Alignment(1, 0.35),
                colors: [Color(0xFFFB8C00), Color(0xFFFFB74D)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    reward,
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small section header with an optional trailing action.
class _MiniHeader extends ConsumerWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const _MiniHeader({required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: _titleStyle),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action!,
              style: AppTextStyles.bodySmall.copyWith(
                color: ref.watch(brandPaletteProvider).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Navigates via the single router allowlist (see sections/section_common.dart).
void _navigate(BuildContext context, String deepLink) =>
    navigateDeepLink(context, deepLink);

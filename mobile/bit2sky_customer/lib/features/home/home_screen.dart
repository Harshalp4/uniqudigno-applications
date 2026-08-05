import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/call_fab.dart';
import '../../widgets/design_system.dart';
import '../../widgets/section_entrance.dart';
import 'home_header.dart';
import 'home_section_renderer.dart';
import 'sections/last_viewed_section.dart';

/// Home — dynamic section renderer over /home/layout, rebuilt as a
/// CustomScrollView (redesign §2): a pinned collapsible header sliver, one
/// sliver per section with a one-shot entrance, and bottom padding that keeps
/// the last section clear of the floating dock.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(homeSectionsProvider);
    final palette = ref.watch(brandPaletteProvider);
    final name = ref
        .watch(meProvider)
        .maybeWhen(
          data: (p) => (p?.name != null && p!.name!.trim().isNotEmpty)
              ? p.name!.split(' ').first
              : 'Guest',
          orElse: () => 'Guest',
        );

    final compromised = ref
        .watch(deviceCompromisedProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final body = RefreshIndicator(
      color: palette.primary,
      edgeOffset: topPad + HomeHeaderDelegate.collapsedBody,
      onRefresh: () async {
        ref.invalidate(homeSectionsProvider);
        ref.invalidate(quickActionsProvider);
        ref.invalidate(bannersProvider);
        // Catalogue data too, so deactivated/edited packages and categories
        // drop out on pull-to-refresh (not just restart).
        ref.invalidate(packagesProvider);
        ref.invalidate(packageCategoriesProvider);
        ref.invalidate(popularTestsProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: HomeHeaderDelegate(name: name, topPadding: topPad),
          ),
          if (compromised)
            const SliverToBoxAdapter(child: _SecurityBanner()),
          ...sections.when(
            loading: () => [const SliverToBoxAdapter(child: _HomeSkeleton())],
            error: (_, _) => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s32),
                  child: Center(child: Text('Could not load home.')),
                ),
              ),
            ],
            data: (list) => [
              for (final (i, s) in list.indexed)
                SliverToBoxAdapter(
                  child: SectionEntrance(
                    id: 'home-${s.id}',
                    index: i,
                    child: HomeSectionRenderer(section: s),
                  ),
                ),
              // Client-side browsing history (D2) — no DB seed.
              SliverToBoxAdapter(
                child: SectionEntrance(
                  id: 'home-last-viewed',
                  index: list.length,
                  child: const LastViewedSection(),
                ),
              ),
            ],
          ),
          // Last section never trapped under the floating dock.
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: AppSpacing.bottomNavHeight +
                  AppSpacing.s8 +
                  AppSpacing.sectionGap +
                  bottomPad,
            ),
          ),
        ],
      ),
    );

    // Fixed call-to-book button riding above the dock (Healthians pattern).
    return Stack(
      children: [
        body,
        // extendBody: bottomPad already includes the dock + its margins, so
        // this rides 12pt above the dock's top edge.
        Positioned(
          right: AppSpacing.s8,
          bottom: bottomPad + AppSpacing.s12,
          child: const CallFab(),
        ),
      ],
    );
  }
}

/// Shimmering skeleton mirroring the real section shapes (same heights, same
/// radii) — replaces the old centered spinner.
class _HomeSkeleton extends ConsumerWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    Widget box(double w, double h, {double r = AppRadius.r16}) =>
        SkeletonBox(width: w, height: h, radius: r, palette: palette);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tiles row.
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.cardGap),
                Expanded(child: box(double.infinity, 68, r: AppRadius.r20)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // Promo pair.
          Row(
            children: [
              Expanded(child: box(double.infinity, 112)),
              const SizedBox(width: AppSpacing.cardGap),
              Expanded(child: box(double.infinity, 112)),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // Package rail.
          box(180, 22, r: AppRadius.r8),
          const SizedBox(height: AppSpacing.titleToContent),
          // Mirrors the horizontally-scrolling rail: cards wider than the
          // viewport clip instead of overflowing the fixed-width Row.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.cardGap),
                  box(150, 148),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // Carousel banner 16:7.
          AspectRatio(
            aspectRatio: 16 / 7,
            child: box(double.infinity, double.infinity, r: AppRadius.r20),
          ),
        ],
      ),
    );
  }
}

/// "Unusual activity detected" banner on compromised devices (Section 18).
class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.errorLight,
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        children: [
          const Icon(
            Icons.gpp_bad_outlined,
            color: AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'Unusual activity detected — health data is disabled on this device.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

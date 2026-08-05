import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/catalogue_models.dart';
import '../../../models/content_models.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../providers/catalogue_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/package_card.dart';
import '../../../widgets/pressable.dart';
import 'offers_sheet.dart';

/// D2 §5 — package carousel (redesign §2.5–2.7). Order inside the section:
/// title → offer strip → filter chips → cards. The strip was moved ABOVE the
/// chips so the chip→results mental model stays unbroken (the chips now sit
/// directly on the cards they filter). Chips are 28px pills without per-chip
/// colored icons; cards are the shared 172×168 [PackageCardX]. Hides entirely
/// when the catalogue returns nothing — no fabricated cards.
class PackageCarouselSection extends ConsumerStatefulWidget {
  final HomeSection section;
  const PackageCarouselSection({super.key, required this.section});

  @override
  ConsumerState<PackageCarouselSection> createState() =>
      _PackageCarouselSectionState();
}

class _PackageCarouselSectionState
    extends ConsumerState<PackageCarouselSection> {
  // Selected chip key: '__popular__' or a category id. Null = first chip.
  static const _popularKey = '__popular__';
  String? _selected;
  final _chipScroll = ScrollController();

  @override
  void dispose() {
    _chipScroll.dispose();
    super.dispose();
  }

  String? get _offerStripText {
    final raw = widget.section.config['offerStrip'];
    if (raw is! Map) return null;
    final text = raw['text']?.toString() ?? '';
    return text.isEmpty ? null : text;
  }

  List<Package> _filter(List<Package> all, String selectedKey) {
    if (selectedKey == _popularKey) {
      return all.where((p) => p.isPopular).toList();
    }
    // Category id filter — real many-to-many relationship, not name matching.
    return all.where((p) => p.categoryIds.contains(selectedKey)).toList();
  }

  /// Auto-scroll the selected chip into view (spec §2.5).
  void _revealChip(int index, int total) {
    if (!_chipScroll.hasClients) return;
    final target = (index / (total - 1).clamp(1, 999)) *
        _chipScroll.position.maxScrollExtent;
    _chipScroll.animateTo(
      target.clamp(0, _chipScroll.position.maxScrollExtent),
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(packagesProvider);
    final categories = ref.watch(packageCategoriesProvider).asData?.value ??
        const <CatalogueCategory>[];
    final all = async.asData?.value ?? const <Package>[];
    if (async.isLoading) {
      // Skeleton matches the final rail exactly: title + three 172×168 cards.
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 180, height: 22, palette: palette),
            const SizedBox(height: AppSpacing.titleToContent),
            // Clipped like the real rail — three fixed cards would overflow
            // the screen width otherwise.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.cardGap),
                    SkeletonBox(
                        width: PackageCardX.width,
                        height: PackageCardX.heightFor(context),
                        radius: AppRadius.r16,
                        palette: palette),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (all.isEmpty) return const SizedBox.shrink();

    // Chips = Popular flag + the DB-driven category master. Each chip is a
    // (label, key) pair; key is '__popular__' or a category id.
    final chipPairs = <(String label, String key)>[
      ('Popular', _popularKey),
      for (final c in categories) (c.name, c.id),
    ];
    final selectedKey =
        (_selected != null && chipPairs.any((p) => p.$2 == _selected))
            ? _selected!
            : chipPairs.first.$2;
    final packages = _filter(all, selectedKey);
    final offerText = _offerStripText;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenHPad),
            child: SectionHeader(
              padding: EdgeInsets.zero,
              dense: true,
              title: widget.section.title.isEmpty
                  ? 'Health Packages'
                  : widget.section.title,
              onViewAll: () => context.push('/packages'),
            ),
          ),
          if (offerText != null) ...[
            const SizedBox(height: AppSpacing.titleToContent),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenHPad),
              child: _OfferStrip(text: offerText, palette: palette),
            ),
          ],
          if (chipPairs.length > 1) ...[
            const SizedBox(height: AppSpacing.titleToContent),
            SizedBox(
              height: 28,
              child: ListView.separated(
                controller: _chipScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHPad),
                itemCount: chipPairs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.s8),
                itemBuilder: (context, i) {
                  final (label, key) = chipPairs[i];
                  final active = key == selectedKey;
                  return _FilterChip(
                    label: label,
                    active: active,
                    activeColor: palette.primary,
                    onTap: () {
                      setState(() => _selected = key);
                      _revealChip(i, chipPairs.length);
                    },
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.titleToContent),
          if (packages.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenHPad),
              child: Text(
                'No packages in this category yet.',
                style: AppTextStyles.bodyTight
                    .copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: PackageCardX.heightFor(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHPad),
                itemCount: packages.length,
                itemExtent: PackageCardX.width + AppSpacing.cardGap,
                itemBuilder: (context, i) {
                  final p = packages[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.cardGap),
                    child: PackageCardX(
                      title: p.name,
                      testCount: p.testCount,
                      price: p.price,
                      mrp: p.mrp,
                      palette: palette,
                      heroTag: 'pkg-${p.id}',
                      onTap: () => context.push('/packages/${p.slug}'),
                      onDetails: () => context.push('/packages/${p.slug}'),
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

/// 28px filter chip. Selected: primary fill, white label. Unselected: surface
/// fill, hairline border, secondary label. No per-chip colored icons — they
/// added noise (spec §2.5).
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: active,
        label: 'Filter: $label',
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.easeOut,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeColor : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r100),
            border: Border.all(
              color: active ? activeColor : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.chip.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 48px offer strip (§2.6) — gradient desaturated ~15% toward the surface so
/// it stops out-shouting the package cards it introduces.
class _OfferStrip extends StatelessWidget {
  final String text;
  final dynamic palette;
  const _OfferStrip({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    final a = Color.lerp(palette.primary as Color, AppColors.surface, 0.15)!;
    final b = Color.lerp(palette.accent as Color, AppColors.surface, 0.15)!;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [a, b],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 20, color: Colors.white),
          const SizedBox(width: AppSpacing.cardPad),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMed
                  .copyWith(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Pressable(
            onTap: () => showOffersSheet(context),
            child: Semantics(
              button: true,
              label: 'Claim offer',
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.cardPad, vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text(
                  'Claim',
                  style: AppTextStyles.chip
                      .copyWith(color: palette.primary as Color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

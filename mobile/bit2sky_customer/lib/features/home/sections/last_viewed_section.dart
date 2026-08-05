import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../providers/last_viewed_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/package_card.dart';

/// D2 "Last viewed" — client-side browsing history (Hive), no DB seed.
/// Appended after the DB-driven feed; hidden while the history is empty.
/// Reuses the EXACT same card component as the package carousel (§2.10 —
/// never a second card layout).
class LastViewedSection extends ConsumerWidget {
  const LastViewedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lastViewedProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHPad),
            child: SectionHeader(
                title: 'Last viewed', dense: true, padding: EdgeInsets.zero),
          ),
          const SizedBox(height: AppSpacing.titleToContent),
          SizedBox(
            height: PackageCardX.heightFor(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenHPad),
              itemCount: items.length,
              itemExtent: PackageCardX.width + AppSpacing.cardGap,
              itemBuilder: (context, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.cardGap),
                  child: PackageCardX(
                    title: item.name,
                    price: item.price,
                    mrp: item.mrp ?? item.price,
                    palette: palette,
                    onTap: () => context.push(item.type == 'package'
                        ? '/packages'
                        : '/tests/${item.slug}'),
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

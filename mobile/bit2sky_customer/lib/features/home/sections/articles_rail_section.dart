import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/content_models.dart';
import '../../../providers/articles_provider.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/pressable.dart';

/// D2 §12 — editorial rail from /articles (title, category chip, excerpt).
/// Photography lives in editorial only (design rule); a tinted placeholder
/// covers missing covers. Hidden while there are no published articles.
class ArticlesRailSection extends ConsumerWidget {
  final HomeSection section;
  const ArticlesRailSection({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(articlesProvider);
    final articles = async.asData?.value ?? const <Article>[];
    if (async.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: SkeletonBox(
            width: double.infinity, height: 140, palette: palette),
      );
    }
    if (articles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: SectionHeader(
              dense: true,
              padding: EdgeInsets.zero,
              title: section.title.isEmpty ? 'Health reads' : section.title,
              onViewAll: () => context.push('/articles'),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              itemCount: articles.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
              itemBuilder: (context, i) {
                final a = articles[i];
                return Pressable(
                  onTap: () => context.push('/articles/${a.slug}'),
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((a.category ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s8, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.tint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r100),
                            ),
                            child: Text(
                              a.category!,
                              style: AppTextStyles.label
                                  .copyWith(color: palette.primaryDark),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          a.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        Expanded(
                          child: Text(
                            a.excerpt ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        Text(
                          'Read more',
                          style: AppTextStyles.button
                              .copyWith(color: palette.primary),
                        ),
                      ],
                    ),
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

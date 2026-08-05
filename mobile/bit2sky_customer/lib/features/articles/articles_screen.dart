import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/articles_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/warm_scaffold.dart';

/// Editorial list (D2 articles rail "See all"). Content is DB-driven; the
/// screen shows nothing invented when the CMS is empty.
class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(articlesProvider);
    final articles = async.asData?.value ?? const [];

    return WarmScaffold(
      title: 'Health reads',
      body: async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
              ? Center(
                  child: Text(
                    'No articles yet',
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  itemCount: articles.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s12),
                  itemBuilder: (context, i) {
                    final a = articles[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                        onTap: () => context.push('/articles/${a.slug}'),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.r16),
                            border:
                                Border.all(color: AppColors.borderDefault),
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
                              Text(a.title, style: AppTextStyles.h3),
                              if ((a.excerpt ?? '').isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.s6),
                                Text(
                                  a.excerpt!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Article detail — renders the sanitized HTML body as plain text (tags
/// stripped); a rich HTML renderer can replace this when editorial needs it.
class ArticleDetailScreen extends ConsumerWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  static final _tagPattern = RegExp(r'<[^>]+>');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(articleDetailProvider(slug));
    final article = async.asData?.value;

    return WarmScaffold(
      title: 'Article',
      body: async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : article == null
              ? Center(
                  child: Text(
                    'Article not found',
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    if ((article.category ?? '').isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.tint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text(
                            article.category!,
                            style: AppTextStyles.label
                                .copyWith(color: palette.primaryDark),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(article.title, style: AppTextStyles.display),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      (article.body ?? article.excerpt ?? '')
                          .replaceAll(_tagPattern, '')
                          .trim(),
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                    ),
                  ],
                ),
    );
  }
}

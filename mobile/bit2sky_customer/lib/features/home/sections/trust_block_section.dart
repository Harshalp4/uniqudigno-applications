import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/content_models.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/design_system.dart';
import 'section_common.dart';

/// D2 §11 — trust block: accreditation badges + counters from branding config
/// (operator-entered, hidden while empty — never invented numbers) plus the
/// checkup-journey explainer from the section payload.
class TrustBlockSection extends ConsumerWidget {
  final HomeSection section;
  const TrustBlockSection({super.key, required this.section});

  static const _statLabels = {
    'trust_stat_reports': 'Reports delivered',
    'trust_stat_customers': 'Happy customers',
    'trust_stat_labs': 'Partner labs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final branding = ref.watch(brandingProvider).asData?.value;
    final badges = branding?.trustAccreditations ?? const <String>[];
    final stats = branding?.trustStats ?? const <String, String>{};
    final journey = configItems(section.config, 'journey');

    if (badges.isEmpty && stats.isEmpty && journey.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.title.isNotEmpty) ...[
              SectionHeader(title: section.title, padding: EdgeInsets.zero),
              const SizedBox(height: AppSpacing.s12),
            ],
            if (badges.isNotEmpty) ...[
              TrustBadgeRow(badges: badges, palette: palette),
              const SizedBox(height: AppSpacing.s12),
            ],
            if (stats.isNotEmpty) ...[
              Row(
                children: [
                  for (final entry in stats.entries)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            entry.value,
                            style: AppTextStyles.h2
                                .copyWith(color: palette.primary),
                          ),
                          Text(
                            _statLabels[entry.key] ?? entry.key,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            if (journey.isNotEmpty)
              Row(
                children: [
                  for (final (i, step) in journey.indexed) ...[
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s4),
                          color: palette.tintStrong,
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: palette.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            materialIcon(step['icon']?.toString() ?? ''),
                            size: 16,
                            // Journey icons are the sanctioned home for the
                            // sparing secondary accent (never money/status).
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        SizedBox(
                          width: 72,
                          child: Text(
                            step['label']?.toString() ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

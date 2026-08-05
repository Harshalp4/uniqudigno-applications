import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/content_models.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../widgets/pressable.dart';
import 'section_common.dart';

/// Shared banner card for payload-driven CTA sections (D2 §4 prescription
/// upload, §7 custom-package builder): title + subtitle + single CTA, tinted
/// icon container, hides on an empty payload.
class PayloadBannerSection extends ConsumerWidget {
  final HomeSection section;
  final IconData icon;
  const PayloadBannerSection({
    super.key,
    required this.section,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = section.config['subtitle']?.toString() ?? '';
    final cta = section.config['cta']?.toString() ?? '';
    final deepLink = section.config['deepLink']?.toString();
    if (section.title.isEmpty || cta.isEmpty || deepLink == null) {
      return const SizedBox.shrink();
    }
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
      child: Pressable(
        onTap: () => navigateDeepLink(context, deepLink),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: palette.tint,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: palette.tintStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, color: palette.primary),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: AppTextStyles.h4),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text(
                  cta,
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.textInverse),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

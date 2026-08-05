import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/content_models.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/pressable.dart';

/// D2 §12 — refer & earn banner. Copy comes from the payload; the referral
/// code from /users/me. No reward amounts unless the payload carries them
/// (no live promo config exists — never invent money). Hidden for guests
/// and users without a code.
class ReferEarnSection extends ConsumerWidget {
  final HomeSection section;
  const ReferEarnSection({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headline = section.config['headline']?.toString() ?? '';
    final subtitle = section.config['subtitle']?.toString() ?? '';
    final cta = section.config['cta']?.toString() ?? 'Copy your code';
    final code = ref
        .watch(meProvider)
        .maybeWhen(data: (m) => m?.referralCode, orElse: () => null);
    if (headline.isEmpty || code == null || code.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.moneyAccentLight,
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard,
                color: AppColors.moneyAccentDark, size: 32),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: AppTextStyles.h4),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Pressable(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Referral code $code copied')),
                  );
                }
              },
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}

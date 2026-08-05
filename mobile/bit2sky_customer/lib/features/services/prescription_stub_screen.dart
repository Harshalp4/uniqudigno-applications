import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/warm_scaffold.dart';

/// Prescription-upload landing (D2 §4 stub — the real upload → ops-queue flow
/// ships with D3). Explains the flow; the CTA is explicitly "coming soon" so
/// the home banner never dead-ends.
class PrescriptionStubScreen extends ConsumerWidget {
  const PrescriptionStubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    return WarmScaffold(
      title: 'Book via prescription',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.s24),
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_file_outlined,
                  size: 40, color: palette.primary),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Have a doctor\'s prescription?',
              textAlign: TextAlign.center,
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Soon you\'ll be able to upload it here — our team will match the '
              'prescribed tests and book your home collection for you.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Text(
                'Upload — coming soon',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textDisabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

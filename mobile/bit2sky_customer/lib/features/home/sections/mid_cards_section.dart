import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/content_models.dart';
import '../../../providers/brand_palette_provider.dart';
import '../../../widgets/components.dart';
import '../../../widgets/pressable.dart';
import 'section_common.dart';

/// D2 §4 (reference parity) — two side-by-side mid cards ("Book Via Doctor
/// Prescription" + "Book Lab Tests @ Home"). Titles, colors, badges, and
/// deep links all come from the payload `cards` list; `dark: true` flips the
/// text to white for saturated card colors. Hides on an empty payload.
class MidCardsSection extends ConsumerWidget {
  final HomeSection section;
  const MidCardsSection({super.key, required this.section});

  static Color _bg(Map<String, dynamic> card, Color fallback) {
    final hex = card['bg']?.toString();
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return AppColors.fromHex(hex);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = configItems(section.config, 'cards');
    if (cards.isEmpty) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _MidCard(
                title: card['title']?.toString() ?? '',
                subtitle: card['subtitle']?.toString() ?? '',
                badge: card['badge']?.toString(),
                icon: materialIcon(card['icon']?.toString() ?? ''),
                background: _bg(card, palette.tint),
                dark: card['dark'] == true,
                onTap: () =>
                    navigateDeepLink(context, card['deepLink']?.toString()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MidCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color background;
  final bool dark;
  final VoidCallback onTap;

  const _MidCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.background,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    final fg = dark ? Colors.white : AppColors.textPrimary;
    final fgSoft = dark ? Colors.white70 : AppColors.textSecondary;
    return Pressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 112 * scale,
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.r20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) const SizedBox(height: AppSpacing.s4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h4.copyWith(color: fg, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: fgSoft),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(icon, color: fgSoft, size: 20),
                ),
              ],
            ),
          ),
          // "New" ribbon (payload-driven) — money accent, top-left overhang.
          if (badge != null)
            Positioned(
              top: -6,
              left: AppSpacing.s8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.moneyAccentDark,
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

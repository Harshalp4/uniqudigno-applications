import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'pressable.dart';

/// C5 — Base card (white, radius 16, shadow2).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.shadow2,
        border: border,
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(scale: 0.985, onTap: onTap, child: card);
  }
}

/// C12-style status badge (Normal/High/Low/Critical/etc.).
class StatusBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const StatusBadge({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  factory StatusBadge.normal() => const StatusBadge(
      text: 'Normal',
      background: AppColors.successLight,
      foreground: AppColors.successGreen);
  factory StatusBadge.high() => const StatusBadge(
      text: 'High', background: AppColors.errorLight, foreground: AppColors.errorRed);
  factory StatusBadge.low() => const StatusBadge(
      text: 'Low', background: AppColors.errorLight, foreground: AppColors.errorRed);
  factory StatusBadge.borderline() => const StatusBadge(
      text: 'High',
      background: AppColors.warningLight,
      foreground: AppColors.warningOrange);
  factory StatusBadge.discount(String pct) => StatusBadge(
      text: pct,
      background: AppColors.warningLight,
      foreground: AppColors.warningOrange);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Text(text, style: AppTextStyles.label.copyWith(color: foreground)),
    );
  }
}

/// Section header row: title + optional "View all".
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s24, AppSpacing.s16, AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h2),
          if (onViewAll != null)
            TextButton(onPressed: onViewAll, child: const Text('View all')),
        ],
      ),
    );
  }
}

/// C9 — Quick action tile (48×48 icon container + caption label).
class QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(icon, size: 24, color: AppColors.teal700),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Maps a stored icon name (Material) to an [IconData] (icons from DB are names).
IconData materialIcon(String name) {
  switch (name) {
    case 'home':
      return Icons.home_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'description':
      return Icons.description_rounded;
    case 'monitor_heart':
      return Icons.monitor_heart_rounded;
    case 'person':
      return Icons.person_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'inventory_2':
      return Icons.inventory_2_rounded;
    case 'smart_toy':
      return Icons.smart_toy_rounded;
    default:
      return Icons.circle_outlined;
  }
}

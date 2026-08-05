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

/// Section header row (D1 spec): bold title left, "See all ›" right.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String actionLabel;

  /// Home density redesign: 17/700 [AppTextStyles.sectionTitle] instead of h2.
  final bool dense;

  /// Legacy call sites rely on the default outer spacing; layout-managed
  /// surfaces (D2 home sections) pass [EdgeInsets.zero] and space themselves.
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.actionLabel = 'See all',
    this.dense = false,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.s16, AppSpacing.s24, AppSpacing.s16, AppSpacing.s12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title,
                style: dense ? AppTextStyles.sectionTitle : AppTextStyles.h2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel, style: AppTextStyles.button),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
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
    case 'bloodtype':
      return Icons.bloodtype_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'vaccines':
      return Icons.vaccines_rounded;
    case 'business':
      return Icons.business_rounded;
    case 'medical_services':
      return Icons.medical_services_rounded;
    case 'calendar_month':
      return Icons.calendar_month_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'radar':
      return Icons.radar_rounded;
    case 'female':
      return Icons.female_rounded;
    case 'male':
      return Icons.male_rounded;
    case 'elderly':
      return Icons.elderly_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'health_and_safety':
      return Icons.health_and_safety_rounded;
    case 'wb_sunny':
      return Icons.wb_sunny_rounded;
    case 'battery_alert':
      return Icons.battery_alert_rounded;
    case 'self_improvement':
      return Icons.self_improvement_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'event_available':
      return Icons.event_available_rounded;
    case 'tune':
      return Icons.tune_rounded;
    case 'upload_file':
      return Icons.upload_file_rounded;
    case 'card_giftcard':
      return Icons.card_giftcard_rounded;
    case 'support_agent':
      return Icons.support_agent_rounded;
    case 'autorenew':
      return Icons.autorenew_rounded;
    case 'location_on':
      return Icons.location_on_rounded;
    default:
      return Icons.circle_outlined;
  }
}

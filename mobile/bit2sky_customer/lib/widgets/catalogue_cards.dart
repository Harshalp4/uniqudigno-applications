import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/catalogue_models.dart';
import 'components.dart';

/// C6 — Test card. "Added" state shows a teal left border + tint.
class TestCard extends StatelessWidget {
  final Test test;
  final bool added;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const TestCard({
    super.key,
    required this.test,
    this.added = false,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s12),
      onTap: onTap,
      color: added ? const Color(0xFFFAFFFE) : AppColors.surface,
      border: added
          ? const Border(left: BorderSide(color: AppColors.teal700, width: 3))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  test.name,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${test.parameterCount} parameter'
                      '${test.parameterCount == 1 ? '' : 's'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (test.reportTimeText != null)
                      _ReportTag(text: test.reportTimeText!),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    Text('₹${test.price}', style: AppTextStyles.priceLarge),
                    if (test.discountPercent > 0) ...[
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        '₹${test.mrp}',
                        style: AppTextStyles.priceStrikethrough,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (test.discountPercent > 0)
                _DiscountBadge(percent: test.discountPercent),
              const SizedBox(height: AppSpacing.s16),
              _AddButton(added: added, onTap: onAdd),
            ],
          ),
        ],
      ),
    );
  }
}

/// Green "50% OFF" pill (wireframe `.disc-badge`).
class _DiscountBadge extends StatelessWidget {
  final int percent;
  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '$percent% OFF',
      style: const TextStyle(
        color: Color(0xFF43A047),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Teal "🕐 Report in 6h" tag (wireframe `.tag.teal`).
class _ReportTag extends StatelessWidget {
  final String text;
  const _ReportTag({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.teal50,
      borderRadius: BorderRadius.circular(AppRadius.r8),
    ),
    child: Text(
      '🕐 $text',
      style: const TextStyle(
        color: AppColors.teal700,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Outlined "+ Add" pill → filled "✓ Added" (wireframe `.add-btn`).
class _AddButton extends StatelessWidget {
  final bool added;
  final VoidCallback? onTap;
  const _AddButton({required this.added, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: added ? AppColors.teal700 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.teal700, width: 1.5),
        ),
        child: Text(
          '+ Add',
          style: TextStyle(
            color: added ? Colors.white : AppColors.teal700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// C7 — Package card (gradient header + white body).
class PackageCard extends StatelessWidget {
  final Package package;
  final VoidCallback? onDetails;
  final VoidCallback? onBook;

  const PackageCard({
    super.key,
    required this.package,
    this.onDetails,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.shadow2,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 88,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.packageHeader),
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  package.name,
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${package.testCount} tests · ${package.parameterCount} parameters',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('₹${package.price}', style: AppTextStyles.priceLarge),
                    const SizedBox(width: AppSpacing.s8),
                    if (package.discountPercent > 0)
                      Text(
                        '₹${package.mrp}',
                        style: AppTextStyles.priceStrikethrough,
                      ),
                  ],
                ),
                if (package.saving > 0)
                  Text(
                    'You save ₹${package.saving}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.successGreen,
                    ),
                  ),
                const SizedBox(height: AppSpacing.s12),
                if (onDetails == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Book'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDetails,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('Details'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBook,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('Book'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

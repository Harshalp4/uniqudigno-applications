import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/pressable.dart';

/// "Claim" offers sheet: live coupons (copy to use at checkout) + the
/// already-discounted-prices story, without leaving the dashboard.
Future<void> showOffersSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OffersSheet(),
  );
}

class _OffersSheet extends ConsumerWidget {
  const _OffersSheet();

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons =
        ref.watch(availableCouponsProvider).asData?.value ?? const [];

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD8CDBA),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.s8),
                  Text('Offers for you',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              // Already-discounted story
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2A9C54), Color(0xFF1F7A42)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Up to 76% off — already applied',
                        style: AppTextStyles.h4.copyWith(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        'Every package price you see is the discounted price. '
                        'No code needed.',
                        style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFD7F5E2),
                            fontSize: 10.5)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text('COUPONS — EXTRA SAVINGS AT CHECKOUT',
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.s8),
              if (coupons.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('New coupons drop here — check back soon.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                )
              else
                for (final c in coupons) ...[
                  _CouponCard(coupon: c),
                  const SizedBox(height: AppSpacing.s8),
                ],
              const SizedBox(height: AppSpacing.s8),
              Pressable(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/packages');
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3E7FBE), Color(0xFF2C5F94)]),
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                  child: Text('Browse discounted packages →',
                      style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  final dynamic coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFBFD7EC),
            width: 1.4,
            style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FB),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: const Color(0xFF3E7FBE),
                  width: 1.2,
                  style: BorderStyle.solid),
            ),
            child: Text(coupon.code,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C5F94),
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
                (coupon.description as String?)?.isNotEmpty == true
                    ? coupon.description as String
                    : 'Apply at checkout for extra savings',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5, color: AppColors.textSecondary)),
          ),
          Pressable(
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: coupon.code as String));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                        '${coupon.code} copied — apply it at checkout')));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3E7FBE), Color(0xFF2C5F94)]),
                borderRadius: BorderRadius.circular(AppRadius.r100),
              ),
              child: Text('Copy',
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

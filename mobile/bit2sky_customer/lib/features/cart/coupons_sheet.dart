import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/pressable.dart';

/// Shared "Coupons & offers" picker sheet — used by both My Cart and the
/// Book Collection screen (same server cart, same coupon state).
Future<void> showCouponsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CouponsSheet(),
  );
}

class _CouponsSheet extends ConsumerStatefulWidget {
  const _CouponsSheet();

  @override
  ConsumerState<_CouponsSheet> createState() => _CouponsSheetState();
}

class _CouponsSheetState extends ConsumerState<_CouponsSheet> {
  static const _canvas = Color(0xFFFAF3EA);
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply(String code) async {
    if (code.trim().isEmpty) return;
    setState(() => _busy = true);
    final error =
        await ref.read(cartProvider.notifier).applyCoupon(code.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final coupons =
        ref.watch(availableCouponsProvider).asData?.value ?? const [];
    final applied =
        ref.watch(cartProvider).asData?.value?.couponCode;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('🎟 Coupons & offers',
                  style: AppTextStyles.h2.copyWith(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.s12),
              if (coupons.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('No coupons live right now.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              for (final c in coupons) ...[
                _CouponTicket(
                  code: c.code,
                  description: c.description,
                  minOrderValue: c.minOrderValue,
                  applied: applied == c.code,
                  busy: _busy,
                  onApply: () => _apply(c.code),
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.r100),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 10,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization:
                            TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Have a code? Type it here…',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Pressable(
                    onTap:
                        _busy ? null : () => _apply(_codeCtrl.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFF3E7FBE),
                          Color(0xFF2C5F94)
                        ]),
                        borderRadius:
                            BorderRadius.circular(AppRadius.r100),
                      ),
                      child: Text('Apply',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponTicket extends StatelessWidget {
  final String code;
  final String? description;
  final num? minOrderValue;
  final bool applied;
  final bool busy;
  final VoidCallback onApply;
  const _CouponTicket({
    required this.code,
    this.description,
    this.minOrderValue,
    required this.applied,
    required this.busy,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final green = applied;
    final border =
        green ? const Color(0xFF2A9C54) : const Color(0xFFBFD7EC);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: green ? const Color(0xFFE9F8EE) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: border, width: 1.6, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(code,
                    style: AppTextStyles.h4.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: green
                            ? const Color(0xFF1F7A42)
                            : const Color(0xFF2C5F94))),
              ),
              if (green)
                Text('APPLIED ✓',
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F7A42)))
              else
                Pressable(
                  onTap: busy ? null : onApply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF3E7FBE),
                        Color(0xFF2C5F94)
                      ]),
                      borderRadius:
                          BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('APPLY',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
          if ((description ?? '').isNotEmpty ||
              minOrderValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  [
                    if ((description ?? '').isNotEmpty) description!,
                    if (minOrderValue != null)
                      'min order ₹${minOrderValue!.round()}',
                  ].join(' · '),
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: green
                          ? const Color(0xFF3B7A55)
                          : AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

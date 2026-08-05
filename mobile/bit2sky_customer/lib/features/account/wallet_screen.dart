import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/account_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/pressable.dart';

/// Wallet — warm redesign (profile wireframe 6): gradient balance hero with
/// coin watermark, how-to-earn tiles, dashed receipt-style transactions.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final txns = ref.watch(walletTxnsProvider);
    final tiers = ref.watch(tierBenefitsProvider);
    final palette = ref.watch(brandPaletteProvider);
    final balance = wallet.maybeWhen(
        data: (w) => w?.balance.toStringAsFixed(0) ?? '0',
        orElse: () => '—');
    final lifetime = wallet.maybeWhen(
        data: (w) => w?.lifetimeEarned.toStringAsFixed(0),
        orElse: () => null);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text('My Wallet',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            // ── balance hero ──
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [palette.primary, palette.primaryDark]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(0, 8)),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: -6,
                    top: -12,
                    child: Opacity(
                        opacity: 0.14,
                        child: Text('🪙', style: TextStyle(fontSize: 84))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WALLET BALANCE',
                            style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFCFE2F3),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6)),
                        Text('₹$balance',
                            style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800)),
                        Text(
                            lifetime == null
                                ? 'Use towards any booking'
                                : 'Lifetime earned ₹$lifetime',
                            style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFCFE2F3),
                                fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── how to earn ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
              child: Row(
                children: const [
                  _EarnTile(emoji: '🧪', label: 'Earn on every\nbooking'),
                  SizedBox(width: AppSpacing.s8),
                  _EarnTile(emoji: '🎁', label: '₹200 per\nreferral'),
                  SizedBox(width: AppSpacing.s8),
                  _EarnTile(emoji: '👨‍👩‍👧', label: 'Family booking\nbonus'),
                ],
              ),
            ),
            // ── membership tiers ──
            tiers.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s16,
                          AppSpacing.s16, AppSpacing.s16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Membership benefits',
                              style: AppTextStyles.h2.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                for (final (i, t) in list.indexed) ...[
                                  if (i > 0)
                                    const Divider(
                                        height: 1,
                                        color: Color(0xFFF3EDE2)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.s8),
                                    child: Row(
                                      children: [
                                        const Text('⭐',
                                            style:
                                                TextStyle(fontSize: 16)),
                                        const SizedBox(
                                            width: AppSpacing.s12),
                                        Expanded(
                                            child: Text(t.name,
                                                style: AppTextStyles.h4)),
                                        Text(
                                            '${t.discountPercent.toStringAsFixed(0)}% off',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: const Color(
                                                        0xFF2A9C54))),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            // ── transactions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, AppSpacing.s8),
              child: Text('Transactions',
                  style: AppTextStyles.h2
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: txns.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
                data: (list) => list.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('No transactions yet',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 12,
                                offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (final (i, t) in list.indexed) ...[
                              if (i > 0) const _DashedLine(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s8),
                                child: Row(
                                  children: [
                                    Text(t.isCredit ? '🎉' : '🧾',
                                        style: const TextStyle(
                                            fontSize: 15)),
                                    const SizedBox(
                                        width: AppSpacing.s8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(t.reason,
                                              style: AppTextStyles
                                                  .bodySmall
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight
                                                              .w600)),
                                          if (t.note != null)
                                            Text(t.note!,
                                                style: AppTextStyles
                                                    .caption
                                                    .copyWith(
                                                        color: AppColors
                                                            .textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                        '${t.isCredit ? '+' : '−'} ₹${t.amount.toStringAsFixed(0)}',
                                        style: AppTextStyles.h4.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: t.isCredit
                                                ? const Color(0xFF2A9C54)
                                                : AppColors
                                                    .textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnTile extends StatelessWidget {
  final String emoji;
  final String label;
  const _EarnTile({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B5A77))),
          ],
        ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
                width: 4.5, height: 1.4, color: const Color(0xFFEDE4D3)),
          ),
        );
      },
    );
  }
}

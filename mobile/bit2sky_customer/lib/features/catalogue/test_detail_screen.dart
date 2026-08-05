import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/catalogue_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/last_viewed_provider.dart';
import '../../widgets/pressable.dart';
import 'select_members_screen.dart';

/// Test detail — warm redesign matching the package detail: cream canvas,
/// white hero card with price-first row + trust chips, squiggle sections,
/// parameters as dashed rows, sticky gradient Add-to-Cart (member sheet).
class TestDetailScreen extends ConsumerWidget {
  final String slug;
  const TestDetailScreen({super.key, required this.slug});

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = ref.watch(testDetailProvider(slug));
    final palette = ref.watch(brandPaletteProvider);
    final note = ref.watch(brandingProvider).asData?.value.homeCollectionNote;
    final t = test.asData?.value;
    final cartCount =
        ref.watch(cartProvider).asData?.value?.items.length ?? 0;

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: Icons.shopping_cart_outlined,
                    badge: cartCount,
                    onTap: () => context.push('/cart'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: test.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(
                    child: Text('Could not load this test.')),
                data: (t) =>
                    _Body(test: t, palette: palette, note: note),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          t == null ? null : _AddBar(test: t, palette: palette),
    );
  }
}

class _Body extends ConsumerWidget {
  final Test test;
  final dynamic palette;
  final String? note;
  const _Body({required this.test, required this.palette, this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(testParametersProvider(test.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lastViewedProvider.notifier).record(LastViewedItem(
            type: 'test',
            slug: test.slug,
            name: test.name,
            price: test.price,
            mrp: test.mrp,
            viewedAt: DateTime.now(),
          ));
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 24),
      children: [
        // ── hero card ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 22,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFCDEAEA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🧪', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(test.name,
                  style: AppTextStyles.h1.copyWith(
                      fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                  '${test.parameterCount} parameter${test.parameterCount == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.s12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹${test.price.round()}',
                      style: AppTextStyles.h1.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: palette.primary)),
                  const SizedBox(width: AppSpacing.s8),
                  if (test.mrp > test.price) ...[
                    Text('₹${test.mrp.round()}',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textDisabled,
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: AppSpacing.s8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F8EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          'SAVE ₹${(test.mrp - test.price).round()}',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2A9C54))),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const _TrustChip('✔ Certified labs'),
                  if ((test.reportTimeText ?? '').isNotEmpty)
                    _TrustChip('⏱ ${test.reportTimeText}'),
                  _TrustChip((note ?? '').isNotEmpty
                      ? '🏠 $note'
                      : '🏠 Free home collection'),
                ],
              ),
            ],
          ),
        ),
        if ((test.shortDescription ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 16,
                    offset: Offset(0, 6)),
              ],
            ),
            child: Text(test.shortDescription!,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
        // ── parameters ──
        Padding(
          padding:
              const EdgeInsets.fromLTRB(0, AppSpacing.s20, 0, AppSpacing.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Parameters covered',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 16.5, fontWeight: FontWeight.w800)),
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.tint,
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('${test.parameterCount}',
                        style: AppTextStyles.label
                            .copyWith(color: palette.primaryDark)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              CustomPaint(
                size: const Size(120, 8),
                painter: _SquigglePainter(color: palette.primary),
              ),
            ],
          ),
        ),
        params.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s16),
                  child: CircularProgressIndicator())),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) => list.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'This test reports ${test.parameterCount} parameter${test.parameterCount == 1 ? '' : 's'}. '
                    'Full reference ranges appear on your report.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 16,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (final (i, p) in list.indexed) ...[
                        if (i > 0) const _DashedLine(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.s8),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE9F8EE),
                                    shape: BoxShape.circle),
                                child: const Text('✓',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2A9C54))),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: AppTextStyles.h4),
                                    if ((p.referenceRange ?? '')
                                        .isNotEmpty)
                                      Text('Ref: ${p.referenceRange}',
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  color: AppColors
                                                      .textSecondary)),
                                  ],
                                ),
                              ),
                              if ((p.unit ?? '').isNotEmpty)
                                Text(p.unit!,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textDisabled)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _AddBar extends ConsumerWidget {
  final Test test;
  final dynamic palette;
  const _AddBar({required this.test, required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0E9DC))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${test.price.round()}',
                      style: AppTextStyles.priceLarge
                          .copyWith(color: palette.primary)),
                  if (test.discountPercent > 0)
                    Text(
                        '${test.discountPercent}% off · ₹${test.mrp.round()}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Pressable(
                  onTap: () async {
                    final authed = ref.read(authProvider).status ==
                        AuthStatus.authenticated;
                    String? memberId;
                    if (authed) {
                      final pick = await showMemberSheet(context, ref);
                      if (pick == null) return;
                      memberId = pick.memberId;
                    }
                    final err =
                        await ref.read(cartProvider.notifier).addTest(
                            id: test.id,
                            name: test.name,
                            mrp: test.mrp,
                            price: test.price,
                            familyMemberId: memberId);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(err)));
                    }
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [palette.primary, palette.primaryDark]),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('Add to Cart',
                        style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _CircleButton(
      {required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
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
        child: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String text;
  const _TrustChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FA),
        borderRadius: BorderRadius.circular(AppRadius.r100),
      ),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B5A77))),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;
  const _SquigglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.23, size.height * 0.7)
      ..lineTo(size.width * 0.30, size.height * 0.2)
      ..lineTo(size.width * 0.37, size.height * 0.8)
      ..lineTo(size.width * 0.43, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SquigglePainter old) => old.color != color;
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

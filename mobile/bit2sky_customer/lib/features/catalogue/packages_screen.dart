import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/catalogue_models.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/pressable.dart';
import '../../widgets/warm_scaffold.dart';
import 'select_members_screen.dart';

/// Health Packages — A+B combined (packages_list_combined wireframe):
/// category chips, an adaptive best-value spotlight, and rich compare cards
/// (emoji identity, ribbon, tests bar, ₹/test, one Book action).
class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  static const _canvas = Color(0xFFFAF3EA);
  static const _popularKey = '__popular__';
  String _selected = _popularKey;

  (String, Color) _lookOf(Package p) {
    final n = p.name.toLowerCase();
    if (n.contains('diabet')) return ('🍬', const Color(0xFFFDEBD8));
    if (n.contains('cardiac') || n.contains('heart')) {
      return ('🫀', const Color(0xFFFBDDDD));
    }
    if (n.contains('arthritis') || n.contains('bone')) {
      return ('🦴', const Color(0xFFE8F0DD));
    }
    if (n.contains('fever')) return ('🤒', const Color(0xFFFDEBD8));
    if (n.contains('cancer')) return ('🎗️', const Color(0xFFF8DCD4));
    if (n.contains('women')) return ('👩', const Color(0xFFF8DCD4));
    if (n.contains('men')) return ('👨', const Color(0xFFDDEAF6));
    if (n.contains('senior') || n.contains('elder')) {
      return ('🧓', const Color(0xFFE8F0DD));
    }
    if (n.contains('thyroid')) return ('🦋', const Color(0xFFDDEAF6));
    return ('🩺', const Color(0xFFCDEAEA));
  }

  /// Spotlight gradient + label adapt to the active chip.
  (List<Color>, String) _spotlightStyle(String chipName, Package best) {
    final n = chipName.toLowerCase();
    if (n.contains('women')) {
      return (
        const [Color(0xFFD66BA0), Color(0xFFB4487F)],
        '⭐ RECOMMENDED FOR HER'
      );
    }
    if (n.contains('men')) {
      return (
        const [Color(0xFF4E8FC7), Color(0xFF2F6FA6)],
        '⭐ RECOMMENDED FOR HIM'
      );
    }
    if (n.contains('senior')) {
      return (
        const [Color(0xFF5AA97C), Color(0xFF3B8A5E)],
        '⭐ BEST FOR PARENTS'
      );
    }
    final perTest =
        best.testCount > 0 ? (best.price / best.testCount).round() : 0;
    return (
      const [Color(0xFF3E7FBE), Color(0xFF2C5F94)],
      '⭐ BEST VALUE · ₹$perTest/TEST'
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final all = ref.watch(packagesProvider).asData?.value ?? const [];
    final categories =
        ref.watch(packageCategoriesProvider).asData?.value ?? const [];
    final cartCount =
        ref.watch(cartProvider).asData?.value?.items.length ?? 0;

    final chips = <(String, String)>[
      ('Popular', _popularKey),
      for (final c in categories) (c.name, c.id),
    ];
    final selectedKey = chips.any((c) => c.$2 == _selected)
        ? _selected
        : _popularKey;
    final chipName =
        chips.firstWhere((c) => c.$2 == selectedKey).$1;

    var visible = selectedKey == _popularKey
        ? all.where((p) => p.isPopular).toList()
        : all.where((p) => p.categoryIds.contains(selectedKey)).toList();
    if (visible.isEmpty && selectedKey == _popularKey) visible = List.of(all);

    // Spotlight: best ₹/test among the visible set.
    Package? spotlight;
    for (final p in visible.where((p) => p.testCount > 0)) {
      if (spotlight == null ||
          p.price / p.testCount <
              spotlight.price / spotlight.testCount) {
        spotlight = p;
      }
    }
    final rest =
        visible.where((p) => p.id != spotlight?.id).toList();
    final maxTests = all.fold<int>(1, (m, p) => p.testCount > m ? p.testCount : m);
    final minPrice = visible.isEmpty
        ? 0
        : visible.map((p) => p.price).reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  WarmCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Health Packages',
                          style: AppTextStyles.h2.copyWith(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      CustomPaint(
                        size: const Size(110, 8),
                        painter:
                            _SquigglePainter(color: palette.primary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  WarmCircleButton(
                    icon: Icons.shopping_cart_outlined,
                    badge: cartCount,
                    onTap: () => context.push('/cart'),
                  ),
                ],
              ),
            ),
            // ── chips ──
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final on = chips[i].$2 == selectedKey;
                  return Pressable(
                    onTap: () =>
                        setState(() => _selected = chips[i].$2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: on
                            ? LinearGradient(colors: [
                                palette.primary,
                                palette.primaryDark
                              ])
                            : null,
                        color: on ? null : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.r100),
                        boxShadow: [
                          BoxShadow(
                              color: on
                                  ? const Color(0x553E7FBE)
                                  : const Color(0x0A000000),
                              blurRadius: on ? 12 : 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Center(
                        child: Text(chips[i].$1,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: on
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? Center(
                          child: Text('No packages in $chipName yet.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              AppSpacing.s12,
                              AppSpacing.s16,
                              110),
                          children: [
                            if (selectedKey != _popularKey)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.s8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF8EF),
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppRadius.r12),
                                  border: Border.all(
                                      color: const Color(0xFFBFE8CC),
                                      width: 1.3),
                                ),
                                child: Text(
                                    '$chipName — ${visible.length} package${visible.length == 1 ? '' : 's'} · from ₹${minPrice.round()}',
                                    style: AppTextStyles.caption
                                        .copyWith(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w800,
                                            color: const Color(
                                                0xFF1F7A42))),
                              ),
                            if (spotlight != null)
                              _Spotlight(
                                package: spotlight,
                                style: _spotlightStyle(
                                    chipName, spotlight),
                                emoji: _lookOf(spotlight).$1,
                                onBook: () => showPackageMemberSheet(
                                    context, spotlight!.slug),
                                onTap: () => context.push(
                                    '/packages/${spotlight!.slug}'),
                              ),
                            for (final p in rest)
                              _CompareCard(
                                package: p,
                                look: _lookOf(p),
                                maxTests: maxTests,
                                palette: palette,
                                onBook: () => showPackageMemberSheet(
                                    context, p.slug),
                                onTap: () => context
                                    .push('/packages/${p.slug}'),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spotlight extends StatelessWidget {
  final Package package;
  final (List<Color>, String) style;
  final String emoji;
  final VoidCallback onBook;
  final VoidCallback onTap;
  const _Spotlight({
    required this.package,
    required this.style,
    required this.emoji,
    required this.onBook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saved = (package.mrp - package.price).round();
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.$1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: style.$1.last.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -12,
              child: Opacity(
                  opacity: 0.14,
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 82))),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text(style.$2,
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: style.$1.last)),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(package.name,
                      style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  if ((package.shortDescription ?? '').isNotEmpty)
                    Text(package.shortDescription!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white
                                .withValues(alpha: 0.82),
                            fontSize: 11))
                  else
                    Text('${package.testCount} tests included',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white
                                .withValues(alpha: 0.82),
                            fontSize: 11)),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${package.price.round()}',
                          style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: AppSpacing.s8),
                      if (package.mrp > package.price) ...[
                        Text('₹${package.mrp.round()}',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white
                                    .withValues(alpha: 0.6),
                                fontSize: 12,
                                decoration:
                                    TextDecoration.lineThrough,
                                decorationColor: Colors.white70)),
                        const SizedBox(width: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(
                                AppRadius.r100),
                          ),
                          child: Text('SAVE ₹$saved',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Pressable(
                    onTap: onBook,
                    child: Container(
                      width: double.infinity,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.r100),
                      ),
                      child: Text('BOOK NOW →',
                          style: AppTextStyles.button.copyWith(
                              color: style.$1.last,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final Package package;
  final (String, Color) look;
  final int maxTests;
  final dynamic palette;
  final VoidCallback onBook;
  final VoidCallback onTap;
  const _CompareCard({
    required this.package,
    required this.look,
    required this.maxTests,
    required this.palette,
    required this.onBook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saved = (package.mrp - package.price).round();
    final perTest = package.testCount > 0
        ? (package.price / package.testCount).round()
        : null;
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            if (package.discountPercent > 0)
              Positioned(
                top: 12,
                right: -30,
                child: Transform.rotate(
                  angle: 0.785,
                  child: Container(
                    width: 110,
                    padding:
                        const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    color: const Color(0xFFF58B44),
                    child: Text('${package.discountPercent}% OFF',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: look.$2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(look.$1,
                            style: const TextStyle(fontSize: 19)),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(package.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h4.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            if ((package.shortDescription ?? '')
                                .isNotEmpty)
                              Text(package.shortDescription!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption
                                      .copyWith(
                                          fontSize: 10,
                                          color: AppColors
                                              .textSecondary)),
                          ],
                        ),
                      ),
                      if (package.isPopular)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF4FB),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.r100),
                            ),
                            child: Text('MOST BOOKED',
                                style: AppTextStyles.caption
                                    .copyWith(
                                        fontSize: 8,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: const Color(
                                            0xFF2C5F94))),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EBDE),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (package.testCount /
                                    maxTests)
                                .clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  palette.primary,
                                  palette.primaryDark
                                ]),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text('${package.testCount} tests',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${package.price.round()}',
                          style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.primary)),
                      const SizedBox(width: 5),
                      if (package.mrp > package.price) ...[
                        Text('₹${package.mrp.round()}',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.textDisabled,
                                decoration:
                                    TextDecoration.lineThrough)),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F8EE),
                            borderRadius: BorderRadius.circular(
                                AppRadius.r100),
                          ),
                          child: Text('SAVE ₹$saved',
                              style: AppTextStyles.caption
                                  .copyWith(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(
                                          0xFF2A9C54))),
                        ),
                      ],
                      if (perTest != null) ...[
                        const SizedBox(width: 5),
                        Text('· ₹$perTest/test',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ],
                      const Spacer(),
                      Pressable(
                        onTap: onBook,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              palette.primary,
                              palette.primaryDark
                            ]),
                            borderRadius: BorderRadius.circular(
                                AppRadius.r100),
                          ),
                          child: Text('Book',
                              style: AppTextStyles.caption
                                  .copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_palette.dart';
import '../../models/catalogue_models.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/pressable.dart';
import 'select_members_screen.dart';
import 'test_quick_sheet.dart';

/// Category landing (tap Heart / Diabetes / Women's Care from a home rail).
///
/// This is the "pro" internal-screen design language — a gradient hero, a
/// trust strip, a sort control, and elevated package/test cards — meant to be
/// the template the other internal screens adopt. Packages first, then tests.
class CategoryLandingScreen extends ConsumerStatefulWidget {
  final String slug;
  const CategoryLandingScreen({super.key, required this.slug});

  @override
  ConsumerState<CategoryLandingScreen> createState() =>
      _CategoryLandingScreenState();
}

enum _Sort { popular, priceAsc, priceDesc }

class _CategoryLandingScreenState extends ConsumerState<CategoryLandingScreen> {
  _Sort _sort = _Sort.popular;

  List<Package> _sortedPackages(List<Package> p) {
    final list = [...p];
    switch (_sort) {
      case _Sort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _Sort.popular:
        break;
    }
    return list;
  }

  List<Test> _sortedTests(List<Test> t) {
    final list = [...t];
    switch (_sort) {
      case _Sort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _Sort.popular:
        break;
    }
    return list;
  }


  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(categoryLandingProvider(widget.slug));
    final data = async.asData?.value;
    final cart = ref.watch(cartProvider).asData?.value;
    final cartCount = cart?.items.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EA),
      bottomNavigationBar: cartCount > 0
          ? _ViewCartBar(
              count: cartCount,
              total: cart!.payable,
              palette: palette,
            )
          : null,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const Spacer(),
                      Pressable(
                        onTap: () => context.push('/cart'),
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
                          child: Badge(
                            isLabelVisible: cartCount > 0,
                            label: Text('$cartCount'),
                            child: const Icon(Icons.shopping_cart_outlined,
                                size: 20, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(data?.name ?? 'Browse',
                      style: AppTextStyles.h1.copyWith(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  if (data != null) ...[
                    const SizedBox(height: 2),
                    Text(
                        '${data.totalCount} ${data.totalCount == 1 ? 'option' : 'options'} to explore',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 3),
                  CustomPaint(
                    size: const Size(120, 8),
                    painter: _CatSquigglePainter(color: palette.primary),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(categoryLandingProvider(widget.slug)),
              child: async.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : data == null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                                child: Text('Could not load this category.')),
                          ],
                        )
                      : _content(data, palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(CategoryLanding data, BrandPalette palette) {
    if (data.totalCount == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.s24),
        children: [
          const SizedBox(height: 60),
          const Center(child: Text('🔬', style: TextStyle(fontSize: 44))),
          const SizedBox(height: AppSpacing.s12),
          Text('Nothing here yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.s4),
          Text('Explore the full test menu instead.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s16),
          Center(
            child: Pressable(
              onTap: () => context.push('/tests/all'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [palette.primary, palette.primaryDark]),
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text('Browse all tests',
                    style: AppTextStyles.button.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      );
    }

    final packages = _sortedPackages(data.packages);
    final tests = _sortedTests(data.tests);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 32),
      children: [
        _SortBar(
          value: _sort,
          onChanged: (s) => setState(() => _sort = s),
          palette: palette,
        ),
        if (packages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel('Health packages', packages.length),
          const SizedBox(height: AppSpacing.s8),
          for (final p in packages)
            _PackageCardPro(
              package: p,
              palette: palette,
              onAdd: () => showPackageMemberSheet(context, p.slug),
            ),
        ],
        if (tests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s20),
          _SectionLabel('Individual tests', tests.length),
          const SizedBox(height: AppSpacing.s8),
          for (final t in tests)
            _TestRowPro(
              test: t,
              palette: palette,
              onAdd: () => showTestQuickSheet(context, t),
            ),
        ],
      ],
    );
  }
}

/// Brand-gradient hero header with a soft icon watermark and a trust strip —
/// replaces the flat plate app bar.

class _SortBar extends StatelessWidget {
  final _Sort value;
  final ValueChanged<_Sort> onChanged;
  final BrandPalette palette;
  const _SortBar(
      {required this.value, required this.onChanged, required this.palette});

  @override
  Widget build(BuildContext context) {
    final opts = <(_Sort, String)>[
      (_Sort.popular, 'Popular'),
      (_Sort.priceAsc, 'Price: low'),
      (_Sort.priceDesc, 'Price: high'),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.s8),
            child: Icon(Icons.tune_rounded, size: 18, color: AppColors.textSecondary),
          ),
          for (final (s, label) in opts) ...[
            _chip(label, value == s),
            const SizedBox(width: AppSpacing.s8),
          ],
        ]
            .map((w) => Center(child: w))
            .toList(),
      ),
    );
  }

  Widget _chip(String label, bool active) => Pressable(
        onTap: () => onChanged(
            {'Popular': _Sort.popular, 'Price: low': _Sort.priceAsc, 'Price: high': _Sort.priceDesc}[label]!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? palette.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.r100),
            border: Border.all(
                color: active ? palette.primary : AppColors.borderDefault),
          ),
          child: Text(label,
              style: AppTextStyles.label.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final int count;
  const _SectionLabel(this.text, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: AppTextStyles.h3),
        const SizedBox(width: AppSpacing.s8),
        Text('$count',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textDisabled)),
      ],
    );
  }
}

/// Amber money pill — savings / discount (amber reserved for money surfaces).
class _MoneyPill extends StatelessWidget {
  final String text;
  const _MoneyPill(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.moneyAccentLight,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.moneyAccentDark, fontWeight: FontWeight.w800)),
      );
}

class _PackageCardPro extends StatelessWidget {
  final Package package;
  final BrandPalette palette;
  final Future<void> Function() onAdd;
  const _PackageCardPro(
      {required this.package, required this.palette, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final saving = (package.mrp - package.price).round();
    return Pressable(
      onTap: () => context.push('/packages/${package.slug}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r20),
          boxShadow: AppShadows.shadow1,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient leading tile.
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [palette.primary, palette.primaryDark]),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(package.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h4),
                        const SizedBox(height: 3),
                        Text('${package.testCount} tests included',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('₹${package.price.round()}',
                                style: AppTextStyles.priceLarge
                                    .copyWith(color: palette.primary)),
                            const SizedBox(width: 6),
                            if (package.mrp > package.price)
                              Text('₹${package.mrp.round()}',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textDisabled,
                                      decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 6),
                            if (saving > 0) _MoneyPill('Save ₹$saving'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s8,
                  AppSpacing.s12, AppSpacing.s12),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.push('/packages/${package.slug}'),
                    child: Text('View details ›',
                        style: AppTextStyles.button
                            .copyWith(color: palette.primary)),
                  ),
                  const Spacer(),
                  _AddPill(onTap: onAdd, palette: palette),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared "+ Add" pill used on both package cards and test rows so the
/// add-to-cart affordance is identical everywhere on the landing page.
class _AddPill extends StatelessWidget {
  final Future<void> Function() onTap;
  final BrandPalette palette;
  const _AddPill({required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.tint,
          borderRadius: BorderRadius.circular(AppRadius.r100),
          border: Border.all(color: palette.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: palette.primary),
            const SizedBox(width: 2),
            Text('Add',
                style: AppTextStyles.label.copyWith(
                    color: palette.primary, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _TestRowPro extends StatelessWidget {
  final Test test;
  final BrandPalette palette;
  final Future<void> Function() onAdd;
  const _TestRowPro(
      {required this.test, required this.palette, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final saving = (test.mrp - test.price).round();
    return Pressable(
      onTap: () => context.push('/tests/${test.slug}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.shadow1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.tint,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(Icons.science_rounded, size: 20, color: palette.primary),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${test.parameterCount} parameters',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Text('₹${test.price.round()}',
                          style: AppTextStyles.label
                              .copyWith(color: palette.primary, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 5),
                      if (test.mrp > test.price)
                        Text('₹${test.mrp.round()}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textDisabled,
                                decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  if (saving > 0) ...[
                    const SizedBox(height: 5),
                    _MoneyPill('Save ₹$saving'),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            _AddPill(onTap: onAdd, palette: palette),
          ],
        ),
      ),
    );
  }
}

/// Sticky "View Cart" bar — appears whenever the cart has items, so the user
/// can jump straight to checkout after adding from the landing page.
class _ViewCartBar extends StatelessWidget {
  final int count;
  final num total;
  final BrandPalette palette;
  const _ViewCartBar(
      {required this.count, required this.total, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Pressable(
            onTap: () => context.push('/cart'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Row(
                children: [
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}  ·  ₹${total.round()}',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  Text('View Cart',
                      style: AppTextStyles.button.copyWith(color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _CatSquigglePainter extends CustomPainter {
  final Color color;
  const _CatSquigglePainter({required this.color});

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
  bool shouldRepaint(_CatSquigglePainter old) => old.color != color;
}

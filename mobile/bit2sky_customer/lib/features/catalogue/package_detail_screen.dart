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
import '../../providers/last_viewed_provider.dart';
import '../../widgets/pressable.dart';
import 'select_members_screen.dart';

/// Package detail — warm-design rewrite (wireframe A): cream canvas, white
/// hero card with corner discount ribbon, price-first row, dashed test list
/// with collapse, and a sticky Add-to-Cart bar that opens the member sheet
/// (wireframe B) on the same screen instead of navigating away.
class PackageDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const PackageDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<PackageDetailScreen> createState() =>
      _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<PackageDetailScreen> {
  static const _canvas = Color(0xFFFAF3EA);
  static const _collapsedTests = 6;
  bool _showAllTests = false;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(packageDetailProvider(widget.slug));
    final pkg = async.asData?.value;
    final cartCount =
        ref.watch(cartProvider).asData?.value?.items.length ?? 0;

    if (pkg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(lastViewedProvider.notifier).record(LastViewedItem(
              type: 'package',
              slug: pkg.slug,
              name: pkg.name,
              price: pkg.price,
              mrp: pkg.mrp,
              viewedAt: DateTime.now(),
            ));
      });
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── floating circular back + cart ──
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
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(packageDetailProvider(widget.slug)),
                child: async.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : pkg == null
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                  child:
                                      Text('Could not load this package.')),
                            ],
                          )
                        : _buildBody(pkg, palette),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          pkg == null ? null : _StickyBar(package: pkg, palette: palette),
    );
  }

  Widget _buildBody(PackageDetail pkg, dynamic palette) {
    final tests = _showAllTests
        ? pkg.includedTests
        : pkg.includedTests.take(_collapsedTests).toList();
    final hiddenCount = pkg.includedTests.length - _collapsedTests;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 24),
      children: [
        // ── hero card: ribbon, icon, name, price-first, trust chips ──
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
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
            child: Stack(
              children: [
                if (pkg.discountPercent > 0)
                  Positioned(
                    top: 8,
                    right: -34,
                    child: Transform.rotate(
                      angle: 0.785,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        alignment: Alignment.center,
                        color: const Color(0xFFF58B44),
                        child: Text('${pkg.discountPercent}% OFF',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                Column(
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
                      child: const Text('🧪',
                          style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(pkg.name,
                        style: AppTextStyles.h1.copyWith(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                        '${pkg.testCount} tests · ${pkg.parameterCount} parameters',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('₹${pkg.price.round()}',
                            style: AppTextStyles.h1.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: palette.primary)),
                        const SizedBox(width: AppSpacing.s8),
                        if (pkg.mrp > pkg.price)
                          Text('₹${pkg.mrp.round()}',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textDisabled,
                                  decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: AppSpacing.s8),
                        if (pkg.mrp > pkg.price)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F8EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                'SAVE ₹${(pkg.mrp - pkg.price).round()}',
                                style: AppTextStyles.caption.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2A9C54))),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        const _TrustChip('✔ Certified labs'),
                        if ((pkg.reportTimeText ?? '').isNotEmpty)
                          _TrustChip('⏱ ${pkg.reportTimeText}'),
                        const _TrustChip('🏠 Free home collection'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        // ── fasting / sample facts card ──
        _WarmCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pkg.fastingRequired ? '🚫🍽' : '🍽',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        pkg.fastingRequired
                            ? (pkg.fastingHours != null
                                ? '${pkg.fastingHours}–${pkg.fastingHours! + 2} hrs fasting required'
                                : 'Fasting required')
                            : 'No fasting needed',
                        style: AppTextStyles.h4),
                    if ((pkg.sampleType ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Sample: ${pkg.sampleType}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    if ((pkg.shortDescription ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(pkg.shortDescription!,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── What's included ──
        _SquiggleTitle("What's included",
            badge: '${pkg.testCount} tests', palette: palette),
        if (pkg.includedTests.isEmpty)
          _WarmCard(
            child: Text(
              'This package covers ${pkg.parameterCount} parameters across '
              '${pkg.testCount} tests.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          _WarmCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
            child: Column(
              children: [
                for (final (i, t) in tests.indexed) ...[
                  if (i > 0) const _DashedDivider(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s8),
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
                            child: Text(t.name, style: AppTextStyles.h4)),
                        Text(
                            '${t.parameterCount} param${t.parameterCount == 1 ? '' : 's'}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textDisabled)),
                      ],
                    ),
                  ),
                ],
                if (hiddenCount > 0)
                  Pressable(
                    onTap: () =>
                        setState(() => _showAllTests = !_showAllTests),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s8),
                      child: Text(
                          _showAllTests
                              ? 'Show less ⌃'
                              : 'Show all ${pkg.includedTests.length} tests ⌄',
                          style: AppTextStyles.captionMed.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        // ── About / recommended / preparation ──
        if ((pkg.description ?? '').isNotEmpty) ...[
          _SquiggleTitle('About this package', palette: palette),
          _WarmCard(
            child: Text(pkg.description!,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, height: 1.55)),
          ),
        ],
        if ((pkg.recommendedFor ?? '').isNotEmpty) ...[
          _SquiggleTitle('Who should take this', palette: palette),
          _WarmCard(
            child: Text(pkg.recommendedFor!,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, height: 1.55)),
          ),
        ],
        if ((pkg.preparation ?? '').isNotEmpty) ...[
          _SquiggleTitle('How to prepare', palette: palette),
          _WarmCard(
            child: Text(pkg.preparation!,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, height: 1.55)),
          ),
        ],
        // ── FAQs ──
        if (pkg.faqs.isNotEmpty) ...[
          _SquiggleTitle('Frequently asked questions', palette: palette),
          _WarmCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, f) in pkg.faqs.indexed) ...[
                  if (i > 0) const _DashedDivider(),
                  Theme(
                    data: ThemeData(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16),
                      childrenPadding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      iconColor: palette.primary,
                      collapsedIconColor: AppColors.textSecondary,
                      title: Text(f.question, style: AppTextStyles.h4),
                      children: [
                        Text(f.answer,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
      ],
    );
  }
}

/// Round white floating button used for back / cart on the cream canvas.
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

/// White content card on the cream canvas.
class _WarmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _WarmCard(
      {required this.child,
      this.padding = const EdgeInsets.all(AppSpacing.s16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// Section title with the small ECG squiggle underline (landing language).
class _SquiggleTitle extends StatelessWidget {
  final String text;
  final String? badge;
  final dynamic palette;
  const _SquiggleTitle(this.text, {this.badge, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.s20, 0, AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(text,
                  style: AppTextStyles.h2.copyWith(
                      fontSize: 16.5, fontWeight: FontWeight.w800)),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                  child: Text(badge!,
                      style: AppTextStyles.label
                          .copyWith(color: palette.primaryDark)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          CustomPaint(
            size: const Size(120, 8),
            painter: _SquigglePainter(color: palette.primary),
          ),
        ],
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

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

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
                width: 4.5, height: 1.5, color: const Color(0xFFEDE4D3)),
          ),
        );
      },
    );
  }
}

/// Sticky bottom bar: price block + gradient Add-to-Cart that opens the
/// member sheet over this screen (no navigation).
class _StickyBar extends ConsumerWidget {
  final PackageDetail package;
  final dynamic palette;
  const _StickyBar({required this.package, required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0E9DC))),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹${package.price.round()}',
                    style: AppTextStyles.priceLarge
                        .copyWith(color: palette.primary)),
                if (package.discountPercent > 0)
                  Text(
                      '${package.discountPercent}% off · ₹${package.mrp.round()}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Pressable(
                onTap: () => showPackageMemberSheet(context, package.slug),
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
    );
  }
}

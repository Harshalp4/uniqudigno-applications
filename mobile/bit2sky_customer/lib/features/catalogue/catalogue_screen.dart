import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/catalogue_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/catalogue_cards.dart';
import 'select_members_screen.dart';
import 'test_quick_sheet.dart';
import '../../widgets/pressable.dart';

enum CatalogueView { tests, packages }

/// Catalogue / Test list (Part 6/Screen — book a test) with live search.
class CatalogueScreen extends ConsumerStatefulWidget {
  final CatalogueView view;

  const CatalogueScreen({super.key, this.view = CatalogueView.tests});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _searchCtrl.text = q;
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final tests = ref.watch(testsProvider(_query.isEmpty ? null : _query));
    final inCart = ref.watch(cartTestIdsProvider);
    final cart = ref.watch(cartProvider).asData?.value;
    final palette = ref.watch(brandPaletteProvider);
    final isPackages = widget.view == CatalogueView.packages;
    final note = ref.watch(brandingProvider).asData?.value.homeCollectionNote;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EA),
      body: Column(
        children: [
          // ── warm header: circular back / builder / cart-with-badge ──
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
                      _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                      ),
                      const Spacer(),
                      if (!isPackages) ...[
                        _RoundButton(
                          icon: Icons.tune_rounded,
                          onTap: () =>
                              context.push('/packages/custom/builder'),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                      ],
                      _RoundButton(
                        icon: Icons.shopping_cart_outlined,
                        badge: cart?.items.length ?? 0,
                        onTap: () => context.push('/cart'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(isPackages ? 'Health Packages' : 'Book a Test',
                      style: AppTextStyles.h1.copyWith(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                      isPackages
                          ? 'Curated bundles, one discounted price'
                          : (note ?? 'Search from our full test menu'),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  CustomPaint(
                    size: const Size(120, 8),
                    painter: _SquigglePainter(color: palette.primary),
                  ),
                ],
              ),
            ),
          ),
          if (widget.view == CatalogueView.tests)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s16,
                AppSpacing.s4,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 14,
                        offset: Offset(0, 5)),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: "Search for 'LFT'",
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textDisabled),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          Expanded(
            child: widget.view == CatalogueView.packages
                ? const _PackagesOnlyList()
                : _query.isEmpty
                    // ── pure-search idle state: trending chips only ──
                    ? _TrendingView(onPick: _setQuery)
                    : tests.when(
                        loading: () => const _CareLoading(),
                        error: (_, _) =>
                            _Empty(message: 'Could not load tests.'),
                        data: (list) {
                          final pkgs = ref
                              .watch(packagesProvider)
                              .maybeWhen(
                                  data: (p) => p,
                                  orElse: () => const <Package>[])
                              .where((p) => p.name
                                  .toLowerCase()
                                  .contains(_query.toLowerCase()))
                              .toList();
                          if (list.isEmpty && pkgs.isEmpty) {
                            return _Empty(
                                message: 'No results for "$_query".');
                          }
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              AppSpacing.s8,
                              AppSpacing.s16,
                              112,
                            ),
                            children: [
                              for (final p in pkgs) ...[
                                _SearchPackageRow(
                                  package: p,
                                  onBook: () => showPackageMemberSheet(
                                      context, p.slug),
                                  onTap: () => context
                                      .push('/packages/${p.slug}'),
                                ),
                                const SizedBox(height: AppSpacing.s12),
                              ],
                              for (var i = 0; i < list.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.s12),
                                TestCard(
                                  test: list[i],
                                  added: inCart.contains(list[i].id),
                                  onTap: () => showTestQuickSheet(
                                      context, list[i]),
                                  onAdd: () => showTestQuickSheet(
                                      context, list[i]),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
          ),
          // Sticky "View Cart" footer — always visible above the tab bar
          // whenever the cart has items (works for guests too).
          if (cart != null && cart.items.isNotEmpty)
            _CartBar(
              count: cart.items.length,
              total: cart.payable,
              onTap: () => context.push('/cart'),
            ),
        ],
      ),
    );
  }

}

class _PackagesOnlyList extends ConsumerWidget {
  const _PackagesOnlyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(packagesProvider);

    return packages.when(
      loading: () => const _CareLoading(),
      error: (_, _) => _Empty(message: 'Could not load packages.'),
      data: (list) => list.isEmpty
          ? _Empty(message: 'No packages found.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                112,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (_, i) {
                final p = list[i];
                return SizedBox(
                  height: 126,
                  child: _CarePackageTile(
                    package: p,
                    onBook: () =>
                        showPackageMemberSheet(context, p.slug),
                  ),
                );
              },
            ),
    );
  }
}

class _CarePackageTile extends StatelessWidget {
  final Package package;
  final VoidCallback onBook;

  const _CarePackageTile({required this.package, required this.onBook});

  @override
  Widget build(BuildContext context) {
    // Whole tile is tappable → the package detail screen (same target as the
    // home card's "Details >>"), so there's a detail entry point here too.
    return InkWell(
      onTap: () => context.push('/packages/${package.slug}'),
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.shadow1,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.teal700,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      '${package.testCount} tests · ${package.parameterCount} parameters',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              // Real catalogue prices run to 4 digits + struck MRP — scale the
              // price group down rather than overflowing the fixed-width card.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('₹${package.price}',
                          style: AppTextStyles.priceLarge),
                      const SizedBox(width: AppSpacing.s6),
                      if (package.discountPercent > 0)
                        Text(
                          '₹${package.mrp}',
                          style: AppTextStyles.priceStrikethrough,
                        ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/packages/${package.slug}'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.teal700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                  textStyle: AppTextStyles.button,
                ),
                child: const Text('Details'),
              ),
              const SizedBox(width: AppSpacing.s4),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: AppColors.teal700,
                    foregroundColor: Colors.white,
                    textStyle: AppTextStyles.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                  ),
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _CareLoading extends StatelessWidget {
  const _CareLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        112,
      ),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (_, _) => Container(
        height: 118,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    ),
  );
}

/// Sticky bottom cart bar (like other commerce apps): count + total + View Cart.
class _CartBar extends StatelessWidget {
  final int count;
  final num total;
  final VoidCallback onTap;
  const _CartBar({
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.r100),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF3E7FBE), Color(0xFF2C5F94)]),
            borderRadius: BorderRadius.circular(AppRadius.r100),
          ),
          child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count item${count == 1 ? '' : 's'} added',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'View Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Round white floating button used on the warm header.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _RoundButton(
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

/// Idle search state: trending test chips (from the popular list).
class _TrendingView extends ConsumerWidget {
  final void Function(String) onPick;
  const _TrendingView({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref
        .watch(popularTestsProvider)
        .maybeWhen(data: (t) => t, orElse: () => const <Test>[]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 112),
      children: [
        Text('TRENDING',
            style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final t in popular.take(10))
              Pressable(
                onTap: () => onPick(t.name.split(' ').first),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 8,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Text(t.name,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B5A77))),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        Center(
          child: Column(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 36)),
              const SizedBox(height: AppSpacing.s8),
              Text('Search any test or package',
                  style: AppTextStyles.h4
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('e.g. "CBC", "Thyroid", "Vitamin D"',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Package hit inside search results.
class _SearchPackageRow extends StatelessWidget {
  final Package package;
  final VoidCallback onBook;
  final VoidCallback onTap;
  const _SearchPackageRow(
      {required this.package, required this.onBook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF4FB),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text('📦', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text('${package.testCount} tests · package',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${package.price.round()}',
                    style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3E7FBE))),
                const SizedBox(height: 3),
                Pressable(
                  onTap: onBook,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF3E7FBE),
                        Color(0xFF2C5F94)
                      ]),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('Book',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

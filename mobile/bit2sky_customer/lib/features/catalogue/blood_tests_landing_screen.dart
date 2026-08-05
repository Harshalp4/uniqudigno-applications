import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_palette.dart';
import '../../providers/app_providers.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/cart_snackbar.dart';
import '../../widgets/components.dart';
import '../../widgets/ecg_placeholder.dart';
import '../../widgets/pressable.dart';
import '../home/sections/section_common.dart';
import 'select_members_screen.dart';
import 'test_quick_sheet.dart';

/// Dedicated "Blood Tests" landing (wireframe option B — Warm Brand): cream
/// canvas, ECG divider accents, concern rail, advisor call banner, real
/// package cards with discount ribbons + sheen CTAs, popular tests with
/// quick-add, and gender/age package cards. Opens from the home Blood Tests
/// tile; the Care tab remains the full searchable catalogue.
class BloodTestsLandingScreen extends ConsumerStatefulWidget {
  const BloodTestsLandingScreen({super.key});

  @override
  ConsumerState<BloodTestsLandingScreen> createState() =>
      _BloodTestsLandingScreenState();
}

class _BloodTestsLandingScreenState
    extends ConsumerState<BloodTestsLandingScreen>
    with SingleTickerProviderStateMixin {
  static const _canvas = Color(0xFFFAF3EA);

  /// Shared sheen sweep for every BOOK NOW on the page.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final phone = ref
        .read(brandingProvider)
        .maybeWhen(data: (b) => b.supportPhone, orElse: () => null);
    if (phone == null || phone.isEmpty) {
      showAppSnackBar(context, 'Support line coming soon');
      return;
    }
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) showAppSnackBar(context, 'Could not call $phone');
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final packages = ref.watch(packagesProvider).asData?.value ?? const [];
    final popular = ref.watch(popularTestsProvider).asData?.value ?? const [];
    final allTests = ref.watch(testsProvider(null)).asData?.value ?? const [];
    final concerns = _concernItems();

    // Gender & age cards: known package slugs from the real catalogue.
    final byGender = [
      ('women-profile', const [Color(0xFFD66BA0), Color(0xFFB4487F)], '👩'),
      ('men-profile', const [Color(0xFF4E8FC7), Color(0xFF2F6FA6)], '👨'),
      ('arthritis-profile', const [Color(0xFF5AA97C), Color(0xFF3B8A5E)], '🧓'),
    ]
        .map((g) {
          final p = packages.where((p) => p.slug == g.$1).firstOrNull;
          return p == null ? null : (p, g.$2, g.$3);
        })
        .whereType<(dynamic, List<Color>, String)>()
        .toList();

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            // ── App bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s8, AppSpacing.s8, AppSpacing.s8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text('Blood Tests',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => context.push('/cart'),
                    icon: Badge(
                      isLabelVisible: (ref
                                  .watch(cartProvider)
                                  .asData
                                  ?.value
                                  ?.items
                                  .length ??
                              0) >
                          0,
                      label: Text(
                          '${ref.watch(cartProvider).asData?.value?.items.length ?? 0}'),
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                  ),
                ],
              ),
            ),
            // ── Search (opens the full catalogue) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s16),
              child: GestureDetector(
                onTap: () => context.push('/tests'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16, vertical: 13),
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
                  child: Row(children: [
                    const Icon(Icons.search,
                        size: 20, color: AppColors.textDisabled),
                    const SizedBox(width: AppSpacing.s8),
                    Text("Search for 'LFT'",
                        style: AppTextStyles.body.copyWith(
                            fontSize: 14, color: AppColors.textDisabled)),
                  ]),
                ),
              ),
            ),

            // ── Browse by Health Concern ──
            if (concerns.isNotEmpty) ...[
              _SectionTitle('Browse by Health Concern', palette: palette),
              SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  itemCount: concerns.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s8),
                  itemBuilder: (_, i) =>
                      _ConcernTile(item: concerns[i], palette: palette),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],

            // ── Advisor call banner ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF36B665), Color(0xFF2A9C54)]),
                  borderRadius: BorderRadius.circular(AppRadius.r20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Talk to our health advisors for help choosing the right tests',
                              style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4)),
                          const SizedBox(height: AppSpacing.s8),
                          _CallNowButton(onTap: _call),
                        ],
                      ),
                    ),
                    const Text('👩‍⚕️', style: TextStyle(fontSize: 46)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),

            // ── Packages ──
            if (packages.isNotEmpty) ...[
              _SectionTitle('Full Body Checkup Packages', palette: palette),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  itemCount: packages.length.clamp(0, 8),
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s12),
                  itemBuilder: (_, i) {
                    final p = packages[i];
                    return _LandingPackageCard(
                      package: p,
                      palette: palette,
                      sheen: _sheen,
                      onBook: () =>
                          showPackageMemberSheet(context, p.slug),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],

            // ── Popular tests ──
            if (popular.isNotEmpty) ...[
              _SectionTitle('Popular Blood Tests', palette: palette),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r20),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 16,
                        offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    for (final (i, t) in popular.take(6).indexed) ...[
                      if (i > 0) const _DashedDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('₹${t.price}',
                                      style: AppTextStyles.captionMed
                                          .copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: palette.primary)),
                                ],
                              ),
                            ),
                            Pressable(
                              onTap: () =>
                                  showTestQuickSheet(context, t),
                              child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: palette.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.s4, bottom: AppSpacing.s12),
                      child: Center(
                        child: Pressable(
                          onTap: () => context.push('/tests/all'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s20,
                                vertical: AppSpacing.s8),
                            decoration: BoxDecoration(
                              color: palette.tint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r100),
                            ),
                            child: Text(
                                'View all ${allTests.length} tests →',
                                style: AppTextStyles.captionMed.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.primaryDark)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],

            // ── Gender & age ──
            if (byGender.isNotEmpty) ...[
              _SectionTitle('Packages by Gender & Age', palette: palette),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  itemCount: byGender.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s8),
                  itemBuilder: (_, i) {
                    final (p, colors, emoji) = byGender[i];
                    return Pressable(
                      onTap: () => context.push('/packages/${p.slug}'),
                      child: Container(
                        width: 168,
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colors),
                          borderRadius: BorderRadius.circular(AppRadius.r16),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body.copyWith(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('₹${p.price}',
                                        style: AppTextStyles.body.copyWith(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 5),
                                    Text('₹${p.mrp}',
                                        style: AppTextStyles.caption.copyWith(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            decoration: TextDecoration
                                                .lineThrough)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${p.testCount} tests',
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white70,
                                        fontSize: 10.5)),
                              ],
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 30)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Concern tiles reuse the server-driven ConcernRail section of the home
  /// layout (same labels/deep links) — no second taxonomy to maintain.
  List<Map<String, dynamic>> _concernItems() {
    final sections =
        ref.watch(homeSectionsProvider).asData?.value ?? const [];
    for (final s in sections) {
      if (s.sectionType.toLowerCase() == 'concernrail') {
        final items = s.config['items'];
        if (items is List) {
          return items.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return const [];
  }
}

/// Section title with the small animated ECG underline (Warm Brand accent).
class _SectionTitle extends StatefulWidget {
  final String text;
  final BrandPalette palette;
  const _SectionTitle(this.text, {required this.palette});

  @override
  State<_SectionTitle> createState() => _SectionTitleState();
}

class _SectionTitleState extends State<_SectionTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
      _c.value = 0.7;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text,
              style: AppTextStyles.h2
                  .copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
          SizedBox(
            height: 14,
            width: 120,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: EcgTracePainter(
                    t: _c.value,
                    color: widget.palette.primary.withValues(alpha: 0.55)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcernTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final BrandPalette palette;
  const _ConcernTile({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    final label = item['label']?.toString() ?? '';
    final img = item['imageUrl']?.toString();
    return Pressable(
      onTap: () => navigateDeepLink(context, item['deepLink']?.toString()),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0E000000),
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration:
                  BoxDecoration(color: palette.tint, shape: BoxShape.circle),
              child: (img != null && img.isNotEmpty)
                  ? Image.network(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                          materialIcon(item['icon']?.toString() ?? ''),
                          size: 20,
                          color: palette.primaryDark))
                  : Icon(materialIcon(item['icon']?.toString() ?? ''),
                      size: 20, color: palette.primaryDark),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Call Now pill with a ringing pulse ring.
class _CallNowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CallNowButton({required this.onTap});

  @override
  State<_CallNowButton> createState() => _CallNowButtonState();
}

class _CallNowButtonState extends State<_CallNowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _ring.stop();
    } else if (!_ring.isAnimating) {
      _ring.repeat();
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _ring,
            builder: (context, _) {
              final t = _ring.value;
              return Positioned.fill(
                child: Transform.scale(
                  scale: 1 + 0.25 * t,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                      border: Border.all(
                          width: 2,
                          color:
                              Colors.white.withValues(alpha: 0.6 * (1 - t))),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.r100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.call_rounded,
                    size: 15, color: Color(0xFF2A9C54)),
                const SizedBox(width: 6),
                Text('Call Now',
                    style: AppTextStyles.captionMed.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A9C54))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Warm-brand package card: white, corner discount ribbon, sheen BOOK NOW.
class _LandingPackageCard extends StatelessWidget {
  final dynamic package;
  final BrandPalette palette;
  final Animation<double> sheen;
  final VoidCallback onBook;

  const _LandingPackageCard({
    required this.package,
    required this.palette,
    required this.sheen,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final p = package;
    return Container(
      width: 202,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 7)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Pressable(
                  onTap: () => context.push('/packages/${p.slug}'),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              right: p.discountPercent > 0 ? 26 : 0),
                          child: Text(p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3)),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('🧪 ${p.testCount} Tests',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.moneyAccentDark)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s8, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.tint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r100),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Details',
                                      style: AppTextStyles.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: palette.primaryDark)),
                                  Icon(Icons.chevron_right_rounded,
                                      size: 12,
                                      color: palette.primaryDark),
                                ]),
                          ),
                        ]),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('₹${p.price}',
                                style: AppTextStyles.body.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: palette.primary)),
                            const SizedBox(width: 6),
                            if (p.mrp > p.price)
                              Text('₹${p.mrp}',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textDisabled,
                                      decoration:
                                          TextDecoration.lineThrough)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Pressable(
                onTap: onBook,
                child: Container(
                  width: double.infinity,
                  height: 34,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [palette.primary, palette.primaryDark]),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedBuilder(
                        animation: sheen,
                        builder: (context, _) {
                          final t = Curves.easeInOut
                              .transform((sheen.value / 0.4).clamp(0.0, 1.0));
                          if (t <= 0 || t >= 1) {
                            return const SizedBox.shrink();
                          }
                          return FractionalTranslation(
                            translation: Offset(-1.2 + 2.4 * t, 0),
                            child: Transform.rotate(
                              angle: 0.35,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.30),
                                    Colors.white.withValues(alpha: 0),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Center(
                        child: Text('BOOK NOW →',
                            style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (p.discountPercent > 0)
            Positioned(
              top: 12,
              right: -28,
              child: Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFFFF9A3D), Color(0xFFFF6B35)]),
                  ),
                  child: Text('${p.discountPercent}% OFF',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.5,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEFE7DA)
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 11;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => false;
}

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
import 'test_quick_sheet.dart';

/// All Blood Tests (test-explorer wireframe A + dashboard-style chips):
/// concern filter chips, live filter search, A–Z letter groups, and a
/// draggable alphabet jump rail on the right edge.
class AllTestsScreen extends ConsumerStatefulWidget {
  const AllTestsScreen({super.key});

  @override
  ConsumerState<AllTestsScreen> createState() => _AllTestsScreenState();
}

class _AllTestsScreenState extends ConsumerState<AllTestsScreen> {
  static const _canvas = Color(0xFFFAF3EA);

  /// Concern chips → name keywords. Lab test names are standardised enough
  /// that keyword groups behave like real categories (until the DB tags
  /// tests directly).
  static const _filters = <(String, List<String>)>[
    ('All', []),
    ('🍬 Diabetes', ['sugar', 'hba1c', 'glucose', 'insulin', 'rbs']),
    ('🫀 Heart', ['lipid', 'cholesterol', 'hscrp', 'apolipo', 'homocyst', 'troponin', 'cpk']),
    ('🦋 Thyroid', ['tsh', 't3', 't4', 'thyro']),
    ('🫁 Liver', ['liver', 'lft', 'sgpt', 'sgot', 'bilirubin', 'albumin', 'protein']),
    ('💧 Kidney', ['kidney', 'rft', 'creatinine', 'urea', 'uric', 'urine']),
    ('☀️ Vitamins', ['vitamin', 'b12', 'd3', 'folic']),
    ('🩸 Blood & Iron', ['c.b.c', 'cbc', 'h.b', 'hb', 'iron', 'ferritin', 'esr', 'blood group', 'platelet']),
    ('🦠 Infection', ['hiv', 'hbsag', 'hcv', 'vdrl', 'widal', 'dengue', 'malaria', 'typhoid', 'culture', 'afb']),
    ('👩 Women', ['hcg', 'amh', 'estradiol', 'prolactin', 'fsh', 'lh', 'pcod', 'torch']),
  ];

  final _searchCtrl = TextEditingController();
  final Map<String, GlobalKey> _letterKeys = {};
  String _query = '';
  int _filter = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Test> _visible(List<Test> all) {
    var list = all;
    final keywords = _filters[_filter].$2;
    if (keywords.isNotEmpty) {
      list = list
          .where((t) =>
              keywords.any((k) => t.name.toLowerCase().contains(k)))
          .toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
              (t) => t.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
    return list..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Concern emoji + pastel tint for a test, derived from the keyword groups.
  (String, Color) _lookOf(Test t) {
    final n = t.name.toLowerCase();
    for (final f in _filters.skip(1)) {
      if (f.$2.any((k) => n.contains(k))) {
        final emoji = f.$1.split(' ').first;
        return (emoji, _tints[_filters.indexOf(f) % _tints.length]);
      }
    }
    return ('🧪', const Color(0xFFEDF4FB));
  }

  static const _tints = [
    Color(0xFFEDF4FB), Color(0xFFFBEDED), Color(0xFFFDF3E7),
    Color(0xFFEDF9F1), Color(0xFFF3EDFB), Color(0xFFEDF7FB),
    Color(0xFFFBF9ED), Color(0xFFFBEDF6), Color(0xFFEFF6EE),
    Color(0xFFF6EEF9),
  ];

  String _letterOf(Test t) {
    final c = t.name.trim().toUpperCase();
    return c.isEmpty || !RegExp(r'[A-Z]').hasMatch(c[0]) ? '#' : c[0];
  }

  void _jumpTo(String letter) {
    final key = _letterKeys[letter];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut);
    }
  }


  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final all =
        ref.watch(testsProvider(null)).asData?.value ?? const <Test>[];
    final cartCount =
        ref.watch(cartProvider).asData?.value?.items.length ?? 0;
    final visible = _visible(List.of(all));

    // Group by first letter.
    final groups = <String, List<Test>>{};
    for (final t in visible) {
      groups.putIfAbsent(_letterOf(t), () => []).add(t);
    }
    final letters = groups.keys.toList();
    _letterKeys
      ..clear()
      ..addEntries(letters.map((l) => MapEntry(l, GlobalKey())));

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text('All Blood Tests',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(width: AppSpacing.s8),
                  Text('${all.length}',
                      style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary)),
                  const Spacer(),
                  _RoundButton(
                    icon: Icons.shopping_cart_outlined,
                    badge: cartCount,
                    onTap: () => context.push('/cart'),
                  ),
                ],
              ),
            ),
            // ── filter search ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Filter this list…',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon: Icon(Icons.search,
                        size: 19, color: AppColors.textDisabled),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            // ── concern chips (dashboard style) ──
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
                  final on = _filter == i;
                  return Pressable(
                    onTap: () => setState(() => _filter = i),
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
                        child: Text(_filters[i].$1,
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
            if (_filter != 0 && visible.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(
                        color: const Color(0xFFBFE8CC), width: 1.3),
                  ),
                  child: Text(
                      '${_filters[_filter].$1} — ${visible.length} test${visible.length == 1 ? '' : 's'} · from ₹${visible.map((t) => t.price).reduce((a, b) => a < b ? a : b)}',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F7A42))),
                ),
              ),
            // ── A–Z list + jump rail ──
            Expanded(
              child: all.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? Center(
                          child: Text('No tests match.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)))
                      : Stack(
                          children: [
                            ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.s16, AppSpacing.s8, 34, 110),
                              children: [
                                for (final l in letters) ...[
                                  Padding(
                                    key: _letterKeys[l],
                                    padding: const EdgeInsets.fromLTRB(
                                        0, AppSpacing.s8, 0, AppSpacing.s4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                colors: [
                                                  palette.primary,
                                                  palette.primaryDark
                                                ]),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(l,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  color: Colors.white)),
                                        ),
                                        const SizedBox(
                                            width: AppSpacing.s8),
                                        Text(
                                            '${groups[l]!.length} test${groups[l]!.length == 1 ? '' : 's'}',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: AppColors
                                                        .textSecondary)),
                                        const SizedBox(
                                            width: AppSpacing.s8),
                                        Expanded(
                                          child: Container(
                                              height: 1.4,
                                              color: const Color(
                                                  0xFFEBE1D0)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x0D000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 4)),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        for (final (i, t)
                                            in groups[l]!.indexed) ...[
                                          if (i > 0)
                                            const _DashedLine(),
                                          _TestRow(
                                            test: t,
                                            look: _lookOf(t),
                                            palette: palette,
                                            onTap: () =>
                                                showTestQuickSheet(
                                                    context, t),
                                            onAdd: () =>
                                                showTestQuickSheet(
                                                    context, t),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.s8),
                                ],
                              ],
                            ),
                            // alphabet jump rail
                            if (letters.length > 3)
                              Positioned(
                                right: 4,
                                top: 8,
                                bottom: 90,
                                child: _AlphabetRail(
                                    letters: letters, onJump: _jumpTo),
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

/// Draggable alphabet rail: tap or slide to jump to a letter group.
class _AlphabetRail extends StatelessWidget {
  final List<String> letters;
  final void Function(String) onJump;
  const _AlphabetRail({required this.letters, required this.onJump});

  void _handle(Offset local, double height) {
    if (letters.isEmpty) return;
    final i =
        (local.dy / height * letters.length).clamp(0, letters.length - 1);
    onJump(letters[i.floor()]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return GestureDetector(
          onTapDown: (d) => _handle(d.localPosition, h),
          onVerticalDragUpdate: (d) => _handle(d.localPosition, h),
          child: Container(
            width: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.r100),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final l in letters)
                  Text(l,
                      style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3E7FBE))),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
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


/// Rich test row: concern emoji tile, meta chips, price block, gradient add.
class _TestRow extends StatelessWidget {
  final Test test;
  final (String, Color) look;
  final dynamic palette;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const _TestRow({
    required this.test,
    required this.look,
    required this.palette,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: look.$2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(look.$1, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F1E6),
                          borderRadius:
                              BorderRadius.circular(AppRadius.r100),
                        ),
                        child: Text(
                            '${test.parameterCount} param${test.parameterCount == 1 ? '' : 's'}',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ),
                      if ((test.reportTimeText ?? '').isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF4FB),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text('⏱ ${test.reportTimeText}',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2C5F94))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('₹${test.price}',
                        style: AppTextStyles.h4.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: palette.primary)),
                    if (test.mrp > test.price) ...[
                      const SizedBox(width: 4),
                      Text('₹${test.mrp}',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.textDisabled,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                if (test.discountPercent > 0)
                  Text('${test.discountPercent}% off',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2A9C54))),
              ],
            ),
            const SizedBox(width: AppSpacing.s8),
            Pressable(
              onTap: onAdd,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [palette.primary, palette.primaryDark]),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x403E7FBE),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child:
                    const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

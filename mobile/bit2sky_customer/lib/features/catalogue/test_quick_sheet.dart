import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/cart_models.dart';
import '../../models/catalogue_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/pressable.dart';
import 'select_members_screen.dart' show showAddMemberSheet;

/// Test quick-view sheet (wireframe C): details + what's covered + member
/// avatars + add, all in ONE sheet over the current list. Kills the
/// row → detail screen → add → member sheet chain (4 surfaces → 2 taps).
Future<void> showTestQuickSheet(BuildContext context, Test test) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TestQuickSheet(test: test),
  );
}

class _TestQuickSheet extends ConsumerStatefulWidget {
  final Test test;
  const _TestQuickSheet({required this.test});

  @override
  ConsumerState<_TestQuickSheet> createState() => _TestQuickSheetState();
}

class _TestQuickSheetState extends ConsumerState<_TestQuickSheet> {
  static const _canvas = Color(0xFFFAF3EA);

  String? _memberId; // null = the account holder ("Me")
  bool _showAllParams = false;
  bool _busy = false;

  Future<void> _add() async {
    final t = widget.test;
    setState(() => _busy = true);
    // Same-member duplicate guard: adding twice for one person is never
    // intentional for a lab test.
    final lines =
        ref.read(cartProvider).asData?.value?.items ?? const <CartItem>[];
    final dup =
        lines.any((l) => l.testId == t.id && l.familyMemberId == _memberId);
    if (dup) {
      setState(() => _busy = false);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Already in the cart for this member')));
      return;
    }
    final error = await ref.read(cartProvider.notifier).addTest(
        id: t.id,
        name: t.name,
        mrp: t.mrp,
        price: t.price,
        familyMemberId: _memberId);
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.test;
    final authed =
        ref.watch(authProvider).status == AuthStatus.authenticated;
    final family = authed
        ? (ref.watch(familyProvider).asData?.value ?? const [])
        : const [];
    final meName = ref.watch(meProvider).maybeWhen(
        data: (m) => (m?.name?.trim().isNotEmpty ?? false)
            ? m!.name!.split(' ').first
            : 'Me',
        orElse: () => 'Me');
    final params =
        ref.watch(testParametersProvider(t.id)).asData?.value ?? const [];
    final visibleParams =
        _showAllParams ? params : params.take(4).toList();

    final selectedName = _memberId == null
        ? meName
        : family
                .where((m) => m.id == _memberId)
                .map((m) => m.name.split(' ').first)
                .firstOrNull ??
            'Member';

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82),
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
              // ── header ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCDEAEA),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child:
                        const Text('🧪', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h3.copyWith(
                                fontWeight: FontWeight.w800)),
                        Text(
                            '${t.parameterCount} parameter${t.parameterCount == 1 ? '' : 's'}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${t.price.round()}',
                          style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3E7FBE))),
                      if (t.mrp > t.price)
                        Text('₹${t.mrp.round()}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textDisabled,
                                decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  if ((t.reportTimeText ?? '').isNotEmpty)
                    _Chip('⏱ ${t.reportTimeText}',
                        bg: const Color(0xFFEDF4FB),
                        fg: const Color(0xFF2C5F94)),
                  const _Chip('🏠 Free home collection',
                      bg: Color(0xFFE9F8EE), fg: Color(0xFF1F7A42)),
                  const _Chip('✔ Certified labs'),
                ],
              ),
              if ((t.shortDescription ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(t.shortDescription!,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, height: 1.45)),
              ],
              // ── what's covered ──
              if (params.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Text("What's covered",
                    style: AppTextStyles.h4.copyWith(
                        fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      for (final (i, p) in visibleParams.indexed) ...[
                        if (i > 0) const _DashedLine(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.s8),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE9F8EE),
                                    shape: BoxShape.circle),
                                child: const Text('✓',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2A9C54))),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(
                                child: Text(p.name,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(
                                            fontWeight:
                                                FontWeight.w600)),
                              ),
                              if ((p.unit ?? '').isNotEmpty)
                                Text(p.unit!,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textDisabled)),
                            ],
                          ),
                        ),
                      ],
                      if (params.length > 4)
                        Pressable(
                          onTap: () => setState(
                              () => _showAllParams = !_showAllParams),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.s8),
                            child: Text(
                                _showAllParams
                                    ? 'Show less ⌃'
                                    : 'Show all ${params.length} ⌄',
                                style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3E7FBE))),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              // ── who is this for ──
              const SizedBox(height: AppSpacing.s12),
              Text('Who is this for?',
                  style: AppTextStyles.h4.copyWith(
                      fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.s8),
              SizedBox(
                height: 76,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Avatar(
                      emoji: '👤',
                      bg: const Color(0xFFCDEAEA),
                      name: meName,
                      selected: _memberId == null,
                      onTap: () => setState(() => _memberId = null),
                    ),
                    for (final m in family)
                      _Avatar(
                        emoji: (m.gender ?? '').toLowerCase() == 'female'
                            ? '👩'
                            : '👨',
                        bg: const Color(0xFFF8DCD4),
                        name: m.name.split(' ').first,
                        selected: _memberId == m.id,
                        onTap: () => setState(() => _memberId = m.id),
                      ),
                    if (authed)
                      _Avatar(
                        emoji: '＋',
                        bg: Colors.white,
                        name: 'Add',
                        dashed: true,
                        onTap: () => showAddMemberSheet(context, ref),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              // ── CTA ──
              Pressable(
                onTap: _busy ? null : _add,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3E7FBE), Color(0xFF2C5F94)]),
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(
                          'Add for $selectedName · ₹${t.price.round()}',
                          style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Center(
                child: Pressable(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/tests/${t.slug}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: Text('Full details ›',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3E7FBE))),
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

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip(this.text,
      {this.bg = const Color(0xFFF7F1E6), this.fg = const Color(0xFF75808D)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r100),
      ),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  final Color bg;
  final String name;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;
  const _Avatar({
    required this.emoji,
    required this.bg,
    required this.name,
    this.selected = false,
    this.dashed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s12),
      child: Pressable(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: dashed
                        ? Border.all(
                            color: const Color(0xFFC9BFA9), width: 1.8)
                        : Border.all(
                            color: selected
                                ? const Color(0xFF2A9C54)
                                : Colors.transparent,
                            width: 3),
                  ),
                  child: Text(emoji,
                      style: TextStyle(
                          fontSize: dashed ? 19 : 22,
                          color: dashed
                              ? const Color(0xFF3E7FBE)
                              : null)),
                ),
                if (selected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: Color(0xFF2A9C54),
                          shape: BoxShape.circle),
                      child: const Text('✓',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(name,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    color: dashed
                        ? const Color(0xFF3E7FBE)
                        : selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
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

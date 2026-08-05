import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/cart_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/pressable.dart';
import '../auth/login_sheet.dart';

/// Parses the server's `group_discount_tiers` CSV ("0,15,20,25") — % off per
/// person when the same package is booked for N members in one order.
List<num> groupTiers(Map<String, String?> flags) {
  final raw = flags['group_discount_tiers'] ?? '0,15,20,25';
  final tiers = raw
      .split(',')
      .map((s) => num.tryParse(s.trim()))
      .whereType<num>()
      .toList();
  return tiers.isEmpty ? const [0] : tiers;
}

/// Member-selection bottom sheet (wireframe B): opens over the current screen
/// instead of navigating away. Same tier pricing + checklist as the full
/// screen; on confirm the lines are added and the sheet closes in place.
Future<void> showPackageMemberSheet(
    BuildContext context, String slug) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PackageMemberSheet(slug: slug),
  );
}

class _PackageMemberSheet extends ConsumerStatefulWidget {
  final String slug;
  const _PackageMemberSheet({required this.slug});

  @override
  ConsumerState<_PackageMemberSheet> createState() =>
      _PackageMemberSheetState();
}

class _PackageMemberSheetState extends ConsumerState<_PackageMemberSheet> {
  static const _canvas = Color(0xFFFAF3EA);
  final Set<String?> _selected = {null};
  bool _busy = false;

  num _tierPct(List<num> tiers, int n) =>
      tiers[(n.clamp(1, tiers.length)) - 1];

  Future<void> _confirm(dynamic pkg) async {
    final loggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    // Guests can add for themselves (guest cart); only booking for saved
    // family members genuinely needs an account.
    final needsAccount = _selected.any((id) => id != null);
    if (!loggedIn && needsAccount) {
      final ok = await showLoginSheet(context);
      if (!ok || !mounted) return;
      await ref.read(cartProvider.notifier).mergeGuestCartToServer();
    }
    setState(() => _busy = true);
    final lines =
        ref.read(cartProvider).asData?.value?.items ?? const <CartItem>[];
    String? error;
    for (final memberId in _selected) {
      final dup = lines.any(
          (l) => l.packageId == pkg.id && l.familyMemberId == memberId);
      if (dup) continue;
      error = await ref.read(cartProvider.notifier).addPackage(
            id: pkg.id,
            name: pkg.name,
            mrp: pkg.mrp,
            price: pkg.price,
            familyMemberId: memberId,
          );
      if (error != null) break;
    }
    if (!mounted) return;
    if (error != null) {
      // Keep the sheet open — the user must see the failure, not assume
      // the item silently landed in the cart.
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final pkg = ref.watch(packageDetailProvider(widget.slug)).asData?.value;
    final flags = ref.watch(featureFlagsProvider).asData?.value ??
        const <String, String?>{};
    final tiers = groupTiers(flags);
    final family = ref.watch(familyProvider).asData?.value ?? const [];
    final meName = ref.watch(meProvider).maybeWhen(
        data: (m) => (m?.name?.trim().isNotEmpty ?? false)
            ? m!.name!.split(' ').first
            : 'Me',
        orElse: () => 'Me');

    if (pkg == null) {
      return const SizedBox(
          height: 220, child: Center(child: CircularProgressIndicator()));
    }

    final n = _selected.length;
    final pct = _tierPct(tiers, n);
    final perPerson = (pkg.price * (100 - pct) / 100).round();
    final total = perPerson * n;
    final saved = (pkg.price * n) - total;
    final nextPct = n < tiers.length ? tiers[n] : null;
    final nextPer =
        nextPct == null ? null : (pkg.price * (100 - nextPct) / 100).round();

    return Container(
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          top: AppSpacing.s8,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                decoration: BoxDecoration(
                    color: const Color(0xFFD8CDBA),
                    borderRadius: BorderRadius.circular(3)),
              ),
              // ── gradient header: name + live total ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [palette.primary, palette.primaryDark]),
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pkg.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              '${pkg.testCount} tests · for $n member${n > 1 ? 's' : ''}',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white70)),
                        ]),
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹$total',
                            style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        if (pkg.mrp > pkg.price)
                          Text('₹${pkg.mrp * n}',
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white70,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white70)),
                      ]),
                ]),
              ),
              const SizedBox(height: AppSpacing.s8),
              // ── savings / next-tier nudge ──
              if (saved > 0 || (nextPer != null && nextPer < perPerson))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(
                        color: const Color(0xFFBFE8CC), width: 1.4),
                  ),
                  child: Text(
                      saved > 0
                          ? '🎉 $n members — you save ₹$saved extra!'
                          : '🎉 Add 1 more member — pay just ₹$nextPer/person!',
                      style: AppTextStyles.captionMed.copyWith(
                          color: const Color(0xFF1F7A43),
                          fontWeight: FontWeight.w800)),
                ),
              // ── tier strip ──
              Row(children: [
                for (var i = 0; i < tiers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: (i + 1) == n
                            ? const Color(0xFFEDF4FB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: (i + 1) == n
                                ? palette.primary
                                : Colors.transparent,
                            width: 1.6),
                      ),
                      child: Column(children: [
                        Text('${i + 1}',
                            style: AppTextStyles.body.copyWith(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        Text('member${i > 0 ? 's' : ''}',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 8.5,
                                color: AppColors.textSecondary)),
                        Text(
                            '₹${(pkg.price * (100 - tiers[i]) / 100).round()}${i > 0 ? ' each' : ''}',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2A9C54))),
                      ]),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: AppSpacing.s12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Who is this for?',
                    style: AppTextStyles.h2.copyWith(
                        fontSize: 13.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: AppSpacing.s8),
              // ── member checklist ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                ),
                child: Column(children: [
                  _MemberRow(
                    emoji: '👤',
                    name: meName,
                    detail: 'Self',
                    selected: _selected.contains(null),
                    onTap: () => setState(() {
                      if (_selected.contains(null)) {
                        if (_selected.length > 1) _selected.remove(null);
                      } else {
                        _selected.add(null);
                      }
                    }),
                  ),
                  for (final m in family)
                    _MemberRow(
                      emoji: (m.gender ?? '').toLowerCase() == 'female'
                          ? '👩'
                          : '👨',
                      name: m.name,
                      detail: m.relationship,
                      selected: _selected.contains(m.id),
                      onTap: () => setState(() {
                        if (_selected.contains(m.id)) {
                          if (_selected.length > 1) _selected.remove(m.id);
                        } else {
                          _selected.add(m.id);
                        }
                      }),
                    ),
                  _MemberRow(
                    emoji: '➕',
                    name: 'Add new member',
                    detail: 'Name, age & gender — 30 seconds',
                    selected: false,
                    showBox: false,
                    onTap: () => showAddMemberSheet(context, ref),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.s16),
              Pressable(
                onTap: _busy ? null : () => _confirm(pkg),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [palette.primary, palette.primaryDark]),
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(
                          'Add to Cart · $n member${n > 1 ? 's' : ''} · ₹$total',
                          style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Select Members" (wireframe option A): who is this package for, with
/// tiered per-person group pricing, the family checklist, and inline
/// add-member. Adds one cart line per selected member, then goes to checkout.
class SelectMembersScreen extends ConsumerStatefulWidget {
  final String slug;
  const SelectMembersScreen({super.key, required this.slug});

  @override
  ConsumerState<SelectMembersScreen> createState() =>
      _SelectMembersScreenState();
}

class _SelectMembersScreenState extends ConsumerState<SelectMembersScreen> {
  static const _canvas = Color(0xFFFAF3EA);

  /// Selected member ids; `null` in the set = the account holder ("Me").
  final Set<String?> _selected = {null};
  bool _busy = false;

  num _tierPct(List<num> tiers, int n) =>
      tiers[(n.clamp(1, tiers.length)) - 1];

  Future<void> _continue(dynamic pkg) async {
    final loggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    final needsAccount = _selected.any((id) => id != null);
    if (!loggedIn && needsAccount) {
      final ok = await showLoginSheet(context);
      if (!ok || !mounted) return;
      await ref.read(cartProvider.notifier).mergeGuestCartToServer();
    }
    setState(() => _busy = true);
    // Skip members who already have this package in the cart — tapping
    // "Add to Cart" again must never create duplicate lines for them.
    final lines =
        ref.read(cartProvider).asData?.value?.items ?? const <CartItem>[];
    String? error;
    for (final memberId in _selected) {
      final dup = lines.any(
          (l) => l.packageId == pkg.id && l.familyMemberId == memberId);
      if (dup) continue;
      error = await ref.read(cartProvider.notifier).addPackage(
            id: pkg.id,
            name: pkg.name,
            mrp: pkg.mrp,
            price: pkg.price,
            familyMemberId: memberId,
          );
      if (error != null) break;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(error)));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final pkg = ref.watch(packageDetailProvider(widget.slug)).asData?.value;
    final flags =
        ref.watch(featureFlagsProvider).asData?.value ?? const <String, String?>{};
    final tiers = groupTiers(flags);
    final family = ref.watch(familyProvider).asData?.value ?? const [];
    final meName = ref.watch(meProvider).maybeWhen(
        data: (m) => (m?.name?.trim().isNotEmpty ?? false)
            ? m!.name!.split(' ').first
            : 'Me',
        orElse: () => 'Me');

    if (pkg == null) {
      return const Scaffold(
          backgroundColor: _canvas,
          body: Center(child: CircularProgressIndicator()));
    }

    final n = _selected.length;
    final pct = _tierPct(tiers, n);
    final perPerson = (pkg.price * (100 - pct) / 100).round();
    final total = perPerson * n;
    final nextPct = n < tiers.length ? tiers[n] : null;
    final nextPer =
        nextPct == null ? null : (pkg.price * (100 - nextPct) / 100).round();

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, 0),
              child: Row(children: [
                IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(
                  child: Text('Select Members',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  // ── package header ──
                  Container(
                    margin: const EdgeInsets.all(AppSpacing.s16),
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [palette.primary, palette.primaryDark]),
                      borderRadius: BorderRadius.circular(AppRadius.r20),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pkg.name,
                                  style: AppTextStyles.h3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('${pkg.testCount} tests · $n member${n > 1 ? 's' : ''}',
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white70)),
                            ]),
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹$total',
                                style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            if (pkg.mrp > pkg.price)
                              Text('₹${pkg.mrp * n}',
                                  style: AppTextStyles.caption.copyWith(
                                      color: Colors.white70,
                                      decoration:
                                          TextDecoration.lineThrough,
                                      decorationColor: Colors.white70)),
                          ]),
                    ]),
                  ),
                  // ── add-one-more nudge ──
                  if (nextPer != null && nextPer < perPerson)
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                          AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EF),
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                        border: Border.all(
                            color: const Color(0xFF36B665), width: 1.2),
                      ),
                      child: Text(
                          '🎉 Add 1 more member — pay just ₹$nextPer/person!',
                          style: AppTextStyles.captionMed.copyWith(
                              color: const Color(0xFF1F7A43),
                              fontWeight: FontWeight.w800)),
                    ),
                  // ── tier tiles ──
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16),
                      itemCount: tiers.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.s8),
                      itemBuilder: (_, i) {
                        final count = i + 1;
                        final per =
                            (pkg.price * (100 - tiers[i]) / 100).round();
                        final active = count == n;
                        return Container(
                          width: 92,
                          padding: const EdgeInsets.all(AppSpacing.s8),
                          decoration: BoxDecoration(
                            color: active ? palette.primary : Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppRadius.r16),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x0E000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  '$count Member${count > 1 ? 's' : ''}',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                              const SizedBox(height: 3),
                              Text('₹${per * count}',
                                  style: AppTextStyles.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: active
                                          ? Colors.white
                                          : AppColors.textPrimary)),
                              if (count > 1)
                                Text('₹$per each',
                                    style: AppTextStyles.caption.copyWith(
                                        fontSize: 9,
                                        color: active
                                            ? Colors.white70
                                            : AppColors.textSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, AppSpacing.s8),
                    child: Text('Choose members',
                        style: AppTextStyles.h2.copyWith(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                  ),
                  // ── member list ──
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 14,
                            offset: Offset(0, 5)),
                      ],
                    ),
                    child: Column(children: [
                      _MemberRow(
                        emoji: '👤',
                        name: meName,
                        detail: 'Self',
                        selected: _selected.contains(null),
                        onTap: () => setState(() {
                          if (_selected.contains(null)) {
                            if (_selected.length > 1) _selected.remove(null);
                          } else {
                            _selected.add(null);
                          }
                        }),
                      ),
                      for (final m in family)
                        _MemberRow(
                          emoji: (m.gender ?? '').toLowerCase() == 'female'
                              ? '👩'
                              : '👨',
                          name: m.name,
                          detail: m.relationship,
                          selected: _selected.contains(m.id),
                          onTap: () => setState(() {
                            if (_selected.contains(m.id)) {
                              if (_selected.length > 1) {
                                _selected.remove(m.id);
                              }
                            } else {
                              _selected.add(m.id);
                            }
                          }),
                        ),
                      _MemberRow(
                        emoji: '➕',
                        name: 'Add new member',
                        detail: 'Name, age & gender — 30 seconds',
                        selected: false,
                        showBox: false,
                        onTap: () => showAddMemberSheet(context, ref),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16,
                  AppSpacing.s8, AppSpacing.s16, AppSpacing.s16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : () => _continue(pkg),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.r16)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(
                          'Continue · $n member${n > 1 ? 's' : ''} · ₹$total',
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

class _MemberRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String detail;
  final bool selected;
  final bool showBox;
  final VoidCallback onTap;

  const _MemberRow({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.selected,
    this.showBox = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFF3EDE2), width: 1)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xFFEAF4FB), shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: AppTextStyles.body.copyWith(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              Text(detail,
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5, color: AppColors.textSecondary)),
            ]),
          ),
          if (showBox)
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: selected ? const Color(0xFF36B665) : Colors.white,
                border: Border.all(
                    color: selected
                        ? const Color(0xFF36B665)
                        : const Color(0xFFC6CDD8),
                    width: 1.8),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
        ]),
      ),
    );
  }
}

/// Quick "who is this for?" sheet for single tests (wireframe option B).
/// Returns the picked member id (null = self) or `false` sentinel on dismiss.
Future<({String? memberId, String name})?> showMemberSheet(
    BuildContext context, WidgetRef ref) async {
  final family = ref.read(familyProvider).asData?.value ?? const [];
  final meName = ref.read(meProvider).maybeWhen(
      data: (m) => (m?.name?.trim().isNotEmpty ?? false)
          ? m!.name!.split(' ').first
          : 'Me',
      orElse: () => 'Me');

  return showModalBottomSheet<({String? memberId, String name})>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE3E7ED),
                borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: AppSpacing.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Who is this test for?',
              style: AppTextStyles.h2
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Reports go to the right person.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _memberChip(ctx, '👤 $meName (me)', () =>
              Navigator.pop(ctx, (memberId: null, name: meName))),
          for (final m in family)
            _memberChip(
                ctx,
                '${(m.gender ?? '').toLowerCase() == 'female' ? '👩' : '👨'} ${m.name}',
                () => Navigator.pop(ctx, (memberId: m.id, name: m.name))),
        ]),
      ]),
    ),
  );
}

Widget _memberChip(BuildContext context, String label, VoidCallback onTap) {
  return Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFC9BFAD), width: 1.4),
      ),
      child: Text(label,
          style: AppTextStyles.body
              .copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
    ),
  );
}

/// Inline "add family member" sheet (name, relationship, gender, DOB).
Future<void> showAddMemberSheet(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  String relationship = 'Mother';
  String gender = 'Female';
  DateTime? dob;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12,
            AppSpacing.s16, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE3E7ED),
                  borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: AppSpacing.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Add family member',
                style: AppTextStyles.h2
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Full name', filled: false),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: relationship,
                items: const [
                  'Mother', 'Father', 'Spouse', 'Sibling', 'Child', 'Other'
                ]
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) =>
                    setSheet(() => relationship = v ?? 'Other'),
                decoration: const InputDecoration(
                    labelText: 'Relationship', filled: false),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: gender,
                items: const ['Female', 'Male', 'Other']
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setSheet(() => gender = v ?? 'Other'),
                decoration: const InputDecoration(
                    labelText: 'Gender', filled: false),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime(now.year - 30),
                  firstDate: DateTime(now.year - 110),
                  lastDate: now,
                );
                if (picked != null) setSheet(() => dob = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(dob == null
                  ? 'Date of birth'
                  : '${dob!.day}/${dob!.month}/${dob!.year}'),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          PrimaryButton(
            label: 'Save member',
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final d = dob;
              await ref.read(familyProvider.notifier).add({
                'name': name.text.trim(),
                'relationship': relationship,
                'gender': gender,
                'bloodGroup': 'Unknown',
                if (d != null)
                  'dateOfBirth':
                      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    ),
  );
}

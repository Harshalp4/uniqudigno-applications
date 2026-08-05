import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_palette.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/session_reset.dart';
import '../auth/login_sheet.dart';
import '../../widgets/pressable.dart';
import 'profile_edit_sheet.dart';

/// Profile — 2026 refresh: a tinted identity header (avatar + name + wallet),
/// a 4-up quick-action grid for the most-used destinations, then calm grouped
/// lists (single cards, icon rows, dividers) instead of one tall stack of
/// shouty cards. Guests get a login CTA in the header and no logout row.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final profile =
        ref.watch(meProvider).maybeWhen(data: (m) => m, orElse: () => null);
    final name = (profile?.name?.trim().isNotEmpty ?? false)
        ? profile!.name!
        : 'Guest';
    final contact = (profile?.email?.isNotEmpty ?? false)
        ? profile!.email!
        : (profile?.mobile.isNotEmpty ?? false)
            ? profile!.mobile
            : null;
    final isAuthed =
        ref.watch(authProvider).status == AuthStatus.authenticated;

    // Items needing an account prompt login first when browsing as a guest.
    void gated(VoidCallback action) =>
        isAuthed ? action() : showLoginSheet(context);

    return ColoredBox(
      color: const Color(0xFFFAF3EA),
      child: ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.s8,
        bottom: 96,
      ),
      children: [
        _IdentityHeader(
          palette: palette,
          name: name,
          contact: contact,
          isAuthed: isAuthed,
          onEdit: () => isAuthed
              ? showEditProfileSheet(context)
              : showLoginSheet(context),
        ),
        const SizedBox(height: AppSpacing.s16),

        // ── Most-used destinations as a quick grid ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            children: [
              _QuickTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Bookings',
                  palette: palette,
                  onTap: () => gated(() => context.push('/orders'))),
              const SizedBox(width: AppSpacing.s8),
              _QuickTile(
                  icon: Icons.description_outlined,
                  label: 'Reports',
                  palette: palette,
                  onTap: () => gated(() => context.push('/reports'))),
              const SizedBox(width: AppSpacing.s8),
              _QuickTile(
                  icon: Icons.groups_outlined,
                  label: 'Family',
                  palette: palette,
                  onTap: () => gated(() => context.push('/family'))),
              const SizedBox(width: AppSpacing.s8),
              _QuickTile(
                  icon: Icons.location_on_outlined,
                  label: 'Addresses',
                  palette: palette,
                  onTap: () => gated(() => context.push('/addresses'))),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s20),

        _SectionLabel('Account'),
        _Group(children: [
          _IconRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'My Wallet',
            palette: palette,
            onTap: () => gated(() => context.push('/wallet')),
          ),
          _IconRow(
            icon: Icons.autorenew_rounded,
            title: 'Subscriptions',
            palette: palette,
            onTap: () => gated(() => context.push('/subscriptions')),
          ),
          _IconRow(
            icon: Icons.apartment_rounded,
            title: 'Corporate Verification',
            palette: palette,
            onTap: () => gated(() => context.push('/services/corporate')),
          ),
        ]),

        // ── Refer & Earn banner ──
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
          child: Pressable(
            onTap: () => gated(() => _copyReferral(context, ref)),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2A9C54), Color(0xFF1F7A42)]),
                borderRadius: BorderRadius.circular(AppRadius.r16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x552A9C54),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Refer & Earn ₹200',
                            style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800)),
                        Text('Friends get tested, you get rewarded',
                            style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFD7F5E2),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('Invite',
                        style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF1F7A42),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),

        _SectionLabel('More'),
        _Group(children: [
          _IconRow(
            icon: Icons.support_agent_rounded,
            title: 'Help & Support',
            palette: palette,
            onTap: () => gated(() => context.push('/support')),
          ),
          _IconRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            palette: palette,
            onTap: () => _soon(context, 'Privacy Policy'),
          ),
          if (isAuthed)
            _IconRow(
              icon: Icons.logout_rounded,
              title: 'Log out',
              palette: palette,
              destructive: true,
              onTap: () => _confirmLogout(context, ref),
            ),
        ]),

        const SizedBox(height: AppSpacing.s16),
        Center(
          child: Text(
            'Unique Diagnostic Centre · v$_appVersion',
            style: AppTextStyles.caption
                .copyWith(color: const Color(0xFFB9AF9C)),
          ),
        ),
      ],
    ),
    );
  }

  // Keep in sync with pubspec.yaml version.
  static const _appVersion = '1.0.0';

  Future<void> _copyReferral(BuildContext context, WidgetRef ref) async {
    final code = ref.read(meProvider).asData?.value?.referralCode;
    if (code == null || code.isEmpty) {
      _soon(context, 'Referral program');
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Referral code $code copied — share it!')),
      );
    }
  }

  void _soon(BuildContext context, String what) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$what — coming soon')));

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
            'Are you sure you want to log out of Unique Diagnostic Centre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Logout',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
      invalidateSessionProviders(ref);
      if (context.mounted) context.go('/login');
    }
  }
}

/// Tinted identity card: avatar + name + contact, edit pencil (or a login CTA
/// for guests), and the wallet chip inline for signed-in users.
class _IdentityHeader extends ConsumerWidget {
  final BrandPalette palette;
  final String name;
  final String? contact;
  final bool isAuthed;
  final VoidCallback onEdit;

  const _IdentityHeader({
    required this.palette,
    required this.name,
    required this.contact,
    required this.isAuthed,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = isAuthed
        ? ref
            .watch(walletProvider)
            .maybeWhen(data: (w) => w?.balance ?? 0, orElse: () => 0.0)
        : 0.0;
    final bookings = isAuthed
        ? ref
            .watch(myBookingsProvider)
            .maybeWhen(data: (b) => b.length, orElse: () => 0)
        : 0;
    final reports = isAuthed
        ? ref
            .watch(reportsProvider)
            .maybeWhen(data: (r) => r.length, orElse: () => 0)
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -14,
            child: Opacity(
              opacity: 0.12,
              child: Text('🩺', style: TextStyle(fontSize: 90)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF9CC3E8), width: 3),
                      ),
                      child: isAuthed
                          ? Text(name.substring(0, 1).toUpperCase(),
                              style: AppTextStyles.h2.copyWith(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w800))
                          : Icon(Icons.person_outline_rounded,
                              color: palette.primary, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAuthed ? name : 'Welcome!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              isAuthed
                                  ? (contact ?? '')
                                  : 'Sign in to see bookings & reports',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFFCFE2F3))),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: onEdit,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            isAuthed
                                ? Icons.edit_outlined
                                : Icons.login_rounded,
                            size: 17,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                if (isAuthed)
                  Row(
                    children: [
                      _StatChip(
                          value: '₹${balance.toStringAsFixed(0)}',
                          label: 'Wallet',
                          onTap: () => context.push('/wallet')),
                      const SizedBox(width: AppSpacing.s8),
                      _StatChip(
                          value: '$bookings',
                          label: 'Bookings',
                          onTap: () => context.push('/orders')),
                      const SizedBox(width: AppSpacing.s8),
                      _StatChip(
                          value: '$reports',
                          label: 'Reports',
                          onTap: () => context.push('/reports')),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100)),
                      ),
                      child: Text('Login / Sign up',
                          style: AppTextStyles.button.copyWith(
                              color: palette.primaryDark,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One square quick-action tile (icon + label).
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final BrandPalette palette;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppShadows.hairline),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Icon(icon, size: 20, color: palette.primaryDark),
                ),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20, AppSpacing.s16, AppSpacing.s16, AppSpacing.s8),
      child: Text(text.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11)),
    );
  }
}

/// One grouped card holding compact rows separated by hairline dividers.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.shadow1,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  indent: 56,
                  color: Color(0xFFF0F2F5)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Compact list row: tinted icon square + title + chevron.
class _IconRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final BrandPalette palette;
  final bool destructive;
  final VoidCallback onTap;

  const _IconRow({
    required this.icon,
    required this.title,
    required this.palette,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.errorRed : palette.primaryDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: destructive
                      ? AppColors.errorLight
                      : palette.tint,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(title,
                    style: AppTextStyles.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: destructive
                            ? AppColors.errorRed
                            : AppColors.textPrimary)),
              ),
              if (!destructive)
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent stat chip inside the gradient identity card.
class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _StatChip(
      {required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFCFE2F3), fontSize: 9.5)),
            ],
          ),
        ),
      ),
    );
  }
}

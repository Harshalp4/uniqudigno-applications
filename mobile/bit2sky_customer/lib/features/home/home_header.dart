import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/account_models.dart';
import '../../models/branding_config.dart';
import '../../providers/account_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/guest_cart_provider.dart';
import '../../providers/notifications_provider.dart';

/// Collapsible home header (redesign §2.1).
///
/// Expanded (~148 + status bar): greeting, location, wallet/call actions, an
/// API-driven festive banner slot (§2.2), and the search row. Collapsed
/// (56 + status bar): just the compact search + bell + cart row. The
/// transition is driven continuously by scroll offset — no snap. Background
/// is a soft tint-of-primary → surface gradient, not a saturated slab.
class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String name;
  final double topPadding;

  const HomeHeaderDelegate({required this.name, required this.topPadding});

  static const double expandedBody = 134;
  static const double collapsedBody = 56;

  @override
  double get maxExtent => topPadding + expandedBody;

  @override
  double get minExtent => topPadding + collapsedBody;

  @override
  bool shouldRebuild(covariant HomeHeaderDelegate old) =>
      old.name != name || old.topPadding != topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0); // 0→1
    return _HeaderBody(name: name, topPadding: topPadding, t: t);
  }
}

/// Resolves the festive header banner (§2.2) from the EXISTING /home/layout
/// feed: the section whose `sectionType == 'headertheme'` (documented
/// convention — the API's HomeSection.config is schemaless JSON, so marketing
/// can publish {imageUrl, accentHex?, validFrom?, validTo?} with no backend
/// code change). Client-side date filter; any parse failure → null → the
/// header renders exactly as normal with zero layout shift.
final headerThemeProvider = Provider<({String imageUrl, Color? accent})?>((
  ref,
) {
  final sections = ref.watch(homeSectionsProvider).asData?.value;
  if (sections == null) return null;
  for (final s in sections) {
    if (s.sectionType.toLowerCase() != 'headertheme') continue;
    final img = s.config['imageUrl']?.toString() ?? '';
    if (img.isEmpty) continue;
    final now = DateTime.now();
    final from = DateTime.tryParse(s.config['validFrom']?.toString() ?? '');
    final to = DateTime.tryParse(s.config['validTo']?.toString() ?? '');
    if (from != null && now.isBefore(from)) continue;
    if (to != null && now.isAfter(to)) continue;
    final hex = s.config['accentHex']?.toString();
    return (
      imageUrl: img,
      accent: (hex == null || hex.isEmpty) ? null : AppColors.fromHex(hex),
    );
  }
  return null;
});

class _HeaderBody extends ConsumerWidget {
  final String name;
  final double topPadding;
  final double t;

  const _HeaderBody(
      {required this.name, required this.topPadding, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final theme = ref.watch(headerThemeProvider);
    final tintTop = Color.lerp(
        theme?.accent ?? palette.primary, AppColors.surface, 0.82)!;

    // Everything that belongs only to the expanded state fades/slides out.
    final expandedOpacity = (1 - t * 1.4).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tintTop, AppColors.surface],
          ),
          border: Border(
            bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: t), width: 1),
          ),
        ),
        padding: EdgeInsets.only(top: topPadding),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Festive banner (right-aligned, ≤64 tall, expanded state only).
            if (theme != null)
              Positioned(
                right: AppSpacing.screenHPad,
                top: 4,
                child: Opacity(
                  opacity: expandedOpacity * 0.9,
                  child: SizedBox(
                    height: 64,
                    child: CachedNetworkImage(
                      imageUrl: theme.imageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 480,
                      fadeInDuration: AppMotion.base,
                      // Graceful degradation: nothing on error, no reserved box.
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                      placeholder: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            // Expanded content: greeting + location + tagline, with bell +
            // cart in the top-right (call moved to the floating FAB).
            Positioned(
              left: AppSpacing.screenHPad,
              right: AppSpacing.screenHPad,
              top: 6,
              child: Opacity(
                opacity: expandedOpacity,
                child: IgnorePointer(
                  ignoring: t > 0.5,
                  child: Transform.translate(
                    offset: Offset(0, -10 * t),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, $name', style: AppTextStyles.greeting),
                              const SizedBox(height: 2),
                              const _LocationChip(),
                              const _TaglineLine(),
                            ],
                          ),
                        ),
                        const _WalletChip(),
                        const SizedBox(width: AppSpacing.s8),
                        const _BellButton(),
                        const _CartButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Search row — pinned to the header's bottom edge in BOTH states.
            // Expanded: full-width search (bell + cart live in the top row).
            // Collapsed: the top row is gone, so bell + cart slide in beside
            // the search to keep the 56pt bar fully functional.
            Positioned(
              left: AppSpacing.screenHPad,
              right: AppSpacing.screenHPad,
              bottom: 6,
              child: Row(
                children: [
                  const Expanded(child: _RotatingSearchField()),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: t,
                      child: Opacity(
                        opacity: t,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(width: AppSpacing.s8),
                            _BellButton(),
                            _CartButton(),
                          ],
                        ),
                      ),
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

/// Branding tagline under the location chip — fills the expanded header's
/// empty band with the server-driven brand promise. Never empty: while
/// branding loads, or when the operator hasn't set `app_tagline`, it shows
/// the [BrandingConfig.fallback] line instead of a hole in the header.
class _TaglineLine extends ConsumerWidget {
  const _TaglineLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromApi = ref
        .watch(brandingProvider)
        .maybeWhen(data: (b) => b.tagline, orElse: () => null);
    final tagline = (fromApi == null || fromApi.isEmpty)
        ? BrandingConfig.fallback.tagline!
        : fromApi;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: Text(
        tagline,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionMed
            .copyWith(color: AppColors.textSecondary, letterSpacing: 0.2),
      ),
    );
  }
}

/// Wallet balance chip — hidden for guests and zero/failed balances (no dead
/// UI); taps through to the wallet screen.
class _WalletChip extends ConsumerWidget {
  const _WalletChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).status == AuthStatus.authenticated;
    final balance = ref
        .watch(walletProvider)
        .maybeWhen(data: (w) => w?.balance ?? 0, orElse: () => 0.0);
    if (!loggedIn || balance <= 0) return const SizedBox.shrink();
    final palette = ref.watch(brandPaletteProvider);

    return GestureDetector(
      onTap: () => context.push('/wallet'),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.r100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: palette.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              '₹${balance.toStringAsFixed(0)}',
              style: AppTextStyles.captionMed.copyWith(
                color: palette.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(notificationUnreadCountProvider)
        .maybeWhen(data: (c) => c, orElse: () => 0);
    return _HeaderIconButton(
      icon: Icons.notifications_none_rounded,
      semanticsLabel: 'Notifications',
      badgeCount: unread,
      onTap: () => context.push('/notifications'),
    );
  }
}

class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).status == AuthStatus.authenticated;
    final count = loggedIn
        ? (ref.watch(cartProvider).asData?.value?.items.length ?? 0)
        : ref.watch(guestCartProvider).length;
    return _HeaderIconButton(
      icon: Icons.shopping_cart_outlined,
      semanticsLabel: 'Cart',
      badgeCount: count,
      onTap: () => context.push('/cart'),
    );
  }
}

/// Icon button: visually 8px padding, but a guaranteed ≥44×44 tap target via
/// constraints. Badge count changes pulse 1.0→1.25→1.0 and cross-fade.
class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;
  final String semanticsLabel;

  const _HeaderIconButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void didUpdateWidget(covariant _HeaderIconButton old) {
    super.didUpdateWidget(old);
    if (old.badgeCount != widget.badgeCount && widget.badgeCount > 0) {
      _pulse
        ..duration = AppMotion.of(context, AppMotion.slow)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
    // Overshooting curves (easeOutBack) are illegal on TweenSequence — its
    // transform asserts 0 ≤ t ≤ 1; the 1.25 peak already supplies the emphasis.
    ]).animate(CurvedAnimation(parent: _pulse, curve: AppMotion.easeOut));

    return Semantics(
      button: true,
      label: widget.badgeCount > 0
          ? '${widget.semanticsLabel}, ${widget.badgeCount}'
          : widget.semanticsLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(widget.icon,
                    color: AppColors.textPrimary, size: 24),
                if (widget.badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: ScaleTransition(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.moneyAccent,
                          borderRadius: BorderRadius.circular(AppRadius.r100),
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        child: AnimatedSwitcher(
                          duration: AppMotion.of(context, AppMotion.base),
                          child: Text(
                            widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                            key: ValueKey(widget.badgeCount),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.captionMed.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Location = the user's default saved address (real data). Guests / users with
/// no address see "Set location", which opens the addresses screen.
class _LocationChip extends ConsumerWidget {
  const _LocationChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref
        .watch(addressProvider)
        .maybeWhen(data: (a) => a, orElse: () => const <Address>[]);
    final def = addresses.isEmpty
        ? null
        : addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
    final label = def == null ? 'Set location' : '${def.city}, ${def.state}';

    return GestureDetector(
      onTap: () => context.push('/addresses'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on,
              color: AppColors.textSecondary, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMed
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 16),
        ],
      ),
    );
  }
}

/// 44px pill search field with the rotating placeholder ("Search 'CBC'…"),
/// animated as a slide-up + fade at [AppMotion.base]. Mic sits behind a 1px
/// divider. Surface fill + hairline border — no heavy shadow.
class _RotatingSearchField extends ConsumerStatefulWidget {
  const _RotatingSearchField();

  @override
  ConsumerState<_RotatingSearchField> createState() =>
      _RotatingSearchFieldState();
}

class _RotatingSearchFieldState extends ConsumerState<_RotatingSearchField> {
  Timer? _timer;
  int _index = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer(int count) {
    if (count > 1 && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) setState(() => _index++);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final names = ref.watch(popularTestsProvider).maybeWhen(
        data: (tests) => tests.map((t) => t.name).toList(),
        orElse: () => const <String>[]);
    _ensureTimer(names.length);
    final placeholder = names.isEmpty
        ? 'Search tests, packages, symptoms…'
        : "Search '${names[_index % names.length]}'";

    return Semantics(
      button: true,
      label: 'Search tests and packages',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r100),
          onTap: () => context.push('/tests'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.cardPad),
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.r100),
              border: Border.all(color: AppShadows.hairline),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: 20, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  // Clipped vertical slide so rotating placeholders swap
                  // cleanly instead of cross-fading into overlapping text.
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.base),
                      switchInCurve: AppMotion.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.9),
                          end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: SizedBox(
                        key: ValueKey(placeholder),
                        width: double.infinity,
                        child: Text(
                          placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyTight
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.cardPad),
                Container(width: 1, height: 22, color: AppColors.divider),
                const SizedBox(width: AppSpacing.cardPad),
                Icon(Icons.mic_none_rounded, size: 20, color: palette.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

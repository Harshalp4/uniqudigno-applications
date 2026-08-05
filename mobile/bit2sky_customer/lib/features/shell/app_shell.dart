import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/content_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/components.dart';
import '../care/care_screen.dart';
import '../health/health_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';

/// App shell with a DB-driven bottom navigation bar (Section 8 / C15).
/// Tabs are read from /nav/bottom — never hardcoded.
class AppShell extends ConsumerStatefulWidget {
  final String initialRoute;

  const AppShell({super.key, this.initialRoute = '/home'});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool _syncedInitialRoute = false;

  /// Maps a DB-driven nav route to its screen.
  Widget _pageFor(NavItem item) {
    switch (item.route) {
      case '/home':
        return const HomeScreen();
      case '/care':
        return const CareScreen();
      case '/reports':
        return const ReportsScreen();
      case '/health':
        return const HealthScreen();
      case '/profile':
        return const ProfileScreen();
      default:
        return _Placeholder(title: item.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = ref
        .watch(navItemsProvider)
        .maybeWhen(data: (n) => n, orElse: () => const <NavItem>[]);

    if (navItems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_syncedInitialRoute) {
      final target = navItems.indexWhere(
        (item) => item.route == widget.initialRoute,
      );
      if (target >= 0) _index = target;
      _syncedInitialRoute = true;
    }

    final safeIndex = _index.clamp(0, navItems.length - 1);

    return Scaffold(
      // Content scrolls behind the floating dock (it has its own margin).
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: [for (final item in navItems) _pageFor(item)],
      ),
      bottomNavigationBar: Padding(
        // Hug the bottom edge: overlap most of the home-indicator inset
        // (SafeArea + margin left an ugly dead band under the dock).
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          (MediaQuery.of(context).viewPadding.bottom - 18)
              .clamp(6.0, 24.0),
        ),
        child: _FloatingDock(
          items: navItems,
          activeIndex: safeIndex,
          onSelect: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// Floating capsule dock: detached rounded bar; inactive tabs are icon-only,
/// the active tab expands into a filled brand pill with icon + label. The
/// expansion animates, so switching tabs reads as the pill sliding.
class _FloatingDock extends ConsumerWidget {
  final List<NavItem> items;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _FloatingDock({
    required this.items,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    // Adaptive density: with ≤5 tabs the active pill carries its label; with
    // more (the nav is DB-driven, so ops can add tabs) every tab compacts to
    // an icon and the active one becomes a filled circle — the dock never
    // overflows. Past ~8 tabs a bottom nav is the wrong pattern anyway.
    final compact = items.length > 5;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r100),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppShadows.shadow3,
      ),
      // Content-sized tabs spread edge-to-edge: the first and last items sit
      // at symmetric insets no matter how wide the active pill grows.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            _DockTab(
              item: items[i],
              active: i == activeIndex,
              palette: palette,
              compact: compact,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  final NavItem item;
  final bool active;
  final dynamic palette;
  final bool compact;
  final VoidCallback onTap;

  const _DockTab({
    required this.item,
    required this.active,
    required this.palette,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = palette.navAccent as Color;
    final color = active ? accent : AppColors.textDisabled;
    // Reference-parity: every tab shows icon + label stacked; the active tab
    // sits on a soft accent-tinted pill (compact mode drops the label only if
    // ops ever add enough tabs to crowd the dock).
    final showLabel = !compact;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
              horizontal: showLabel ? AppSpacing.s12 : AppSpacing.s8,
              vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(materialIcon(item.iconUrl), size: 20, color: color),
              if (showLabel) ...[
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — coming soon',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/bookings_provider.dart';
import '../providers/tech_auth_provider.dart';
import 'todays_bookings_screen.dart';

/// Technician home shell — Today / Stats / Profile.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodaysBookingsScreen(), _StatsScreen(), _ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatsScreen extends ConsumerWidget {
  const _StatsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(todaysBookingsProvider).asData?.value ?? [];
    final collected =
        bookings.where((b) => b.status == 'SampleCollected' || b.status == 'InLab').length;
    return Scaffold(
      appBar: AppBar(title: const Text('My Stats')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.s16),
        mainAxisSpacing: AppSpacing.s12,
        crossAxisSpacing: AppSpacing.s12,
        childAspectRatio: 1.3,
        children: [
          _stat('Assigned today', '${bookings.length}', Icons.assignment_outlined),
          _stat('Collected', '$collected', Icons.check_circle_outline),
          _stat('Pending', '${bookings.length - collected}', Icons.schedule),
          _stat('Rating', '4.8 ⭐', Icons.star_outline),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.shadow2,
        ),
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.teal700),
            Text(value, style: AppTextStyles.h1),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _ProfileScreen extends ConsumerWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(
                  backgroundColor: AppColors.teal50,
                  child: Icon(Icons.badge_outlined, color: AppColors.teal700)),
              title: Text('Field Technician'),
              subtitle: Text('VitalScan operations'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(techAuthProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.errorRed),
              label: const Text('Log out', style: TextStyle(color: AppColors.errorRed)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
    );
  }
}

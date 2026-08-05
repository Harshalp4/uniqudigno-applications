import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/partner_provider.dart';
import '../widgets/components.dart';

/// Partner home shell — Dashboard / Bookings / Commissions / Profile.
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
        children: const [
          _DashboardScreen(),
          _BookingsScreen(),
          _CommissionsScreen(),
          _ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardScreen extends ConsumerWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(partnerDashboardProvider).asData?.value ?? const {};
    final bookings = (dash['bookings'] ?? 0).toString();
    final commission = (dash['totalCommission'] ?? 0).toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          Row(
            children: [
              Expanded(child: _metric('Total bookings', bookings, Icons.event_available)),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: _metric('Commission', '₹$commission', Icons.savings_outlined)),
            ],
          ),
          const SectionHeader(title: 'Quick actions'),
          AppCard(
            onTap: () {},
            child: const Row(children: [
              Icon(Icons.add_circle_outline, color: AppColors.teal700),
              SizedBox(width: AppSpacing.s12),
              Text('Create a booking for a customer'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Container(
        decoration: BoxDecoration(
          gradient: AppColors.packageHeader,
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(height: AppSpacing.s8),
            Text(value, style: AppTextStyles.h1.copyWith(color: Colors.white)),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ],
        ),
      );
}

class _BookingsScreen extends ConsumerWidget {
  const _BookingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(partnerBookingsProvider).asData?.value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookings.isEmpty
          ? Center(
              child: Text('No bookings yet',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
              itemBuilder: (_, i) {
                final b = bookings[i] as Map<String, dynamic>;
                return AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_outlined,
                          color: AppColors.teal700),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                          child: Text('#${b['bookingNumber'] ?? ''}',
                              style: AppTextStyles.h4)),
                      StatusBadge.normal(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CommissionsScreen extends ConsumerWidget {
  const _CommissionsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(partnerCommissionsProvider).asData?.value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Commission Statement')),
      body: items.isEmpty
          ? Center(
              child: Text('No commissions yet',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i] as Map<String, dynamic>;
                return ListTile(
                  title: Text('₹${c['commissionAmount'] ?? 0}',
                      style: AppTextStyles.h4),
                  subtitle: Text('Booking ₹${c['bookingAmount'] ?? 0}'),
                  trailing: Text((c['status'] ?? 'accrued').toString()),
                );
              },
            ),
    );
  }
}

class _ProfileScreen extends ConsumerWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC & Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          children: [
            AppCard(
              onTap: () {},
              child: const Row(children: [
                Icon(Icons.upload_file_outlined, color: AppColors.teal700),
                SizedBox(width: AppSpacing.s12),
                Expanded(child: Text('Upload KYC documents')),
                Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ]),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.errorRed),
              label: const Text('Log out',
                  style: TextStyle(color: AppColors.errorRed)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
    );
  }
}

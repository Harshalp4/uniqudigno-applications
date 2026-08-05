import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/bookings_provider.dart';
import '../widgets/components.dart';

/// Today's assigned collections.
class TodaysBookingsScreen extends ConsumerWidget {
  const TodaysBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(todaysBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Collections")),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load bookings.')),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(todaysBookingsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (_, i) {
              final b = list[i];
              return AppCard(
                onTap: () => context.push('/booking/${b.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                      child: const Icon(Icons.water_drop_outlined,
                          color: AppColors.teal700),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#${b.bookingNumber}', style: AppTextStyles.h4),
                          Text(
                            '${b.scheduledTime ?? ''} · ${b.itemCount} test(s)',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      text: b.status,
                      background: AppColors.warningLight,
                      foreground: AppColors.warningOrange,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

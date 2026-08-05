import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/components.dart';
import '../../widgets/warm_scaffold.dart';

/// Subscriptions — list + pause/resume/cancel (own only).
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(subscriptionProvider);

    return WarmScaffold(
      title: 'Subscriptions',
      body: subs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load subscriptions.')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text('No active subscriptions',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
                itemBuilder: (_, i) {
                  final s = list[i];
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text('${s.frequency} plan',
                                    style: AppTextStyles.h4)),
                            StatusBadge(
                              text: s.status,
                              background: s.isActive
                                  ? AppColors.successLight
                                  : AppColors.warningLight,
                              foreground: s.isActive
                                  ? AppColors.successGreen
                                  : AppColors.warningOrange,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          '₹${s.pricePerCycle.toStringAsFixed(0)} / cycle'
                          '${s.nextBookingDate != null ? ' · next ${s.nextBookingDate}' : ''}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Row(
                          children: [
                            if (s.isActive)
                              TextButton(
                                onPressed: () => ref
                                    .read(subscriptionProvider.notifier)
                                    .pause(s.id),
                                child: const Text('Pause'),
                              )
                            else if (s.isPaused)
                              TextButton(
                                onPressed: () => ref
                                    .read(subscriptionProvider.notifier)
                                    .resume(s.id),
                                child: const Text('Resume'),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => ref
                                  .read(subscriptionProvider.notifier)
                                  .cancel(s.id),
                              child: const Text('Cancel',
                                  style: TextStyle(color: AppColors.errorRed)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

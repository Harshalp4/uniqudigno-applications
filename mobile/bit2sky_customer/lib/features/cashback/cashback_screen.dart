import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/misc_provider.dart';
import '../../widgets/components.dart';
import '../../widgets/warm_scaffold.dart';

/// Cashback offers (public, cached 30m server-side).
class CashbackScreen extends ConsumerWidget {
  const CashbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(cashbackOffersProvider);

    return WarmScaffold(
      title: 'Cashback Offers',
      body: offers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Empty(),
        data: (list) => list.isEmpty
            ? const _Empty()
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
                itemBuilder: (_, i) {
                  final o = list[i];
                  return AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                          ),
                          child: const Icon(Icons.savings_outlined,
                              color: AppColors.successGreen),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.title, style: AppTextStyles.h4),
                              if (o.description != null)
                                Text(o.description!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary)),
                              const SizedBox(height: AppSpacing.s4),
                              Text(o.rewardLabel,
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.successGreen)),
                            ],
                          ),
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.savings_outlined,
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.s16),
          Text('No active offers right now',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/notifications_provider.dart';
import '../home/sections/section_common.dart';
import '../../widgets/warm_scaffold.dart';

/// In-app notification centre (D2 header bell). List + tap-to-read +
/// "mark all read"; unread rows get a brand-tint highlight.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final async = ref.watch(notificationsProvider);
    final items = async.asData?.value ?? const [];
    final unread = items.where((n) => !n.isRead).length;

    return WarmScaffold(
      title: 'Notifications',
      subtitle: unread == 0 ? null : '$unread unread',
      actions: [
        if (unread > 0)
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Read all'),
          ),
      ],
      body: Column(children: [
        Expanded(
          child: async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          size: 56, color: AppColors.textDisabled),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        'No notifications yet',
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notificationsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s8),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return Material(
                        color: n.isRead ? Colors.white : palette.tint,
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                          onTap: () {
                            ref
                                .read(notificationsProvider.notifier)
                                .markRead(n.id);
                            if (n.deepLink != null) {
                              navigateDeepLink(context, n.deepLink);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  n.isRead
                                      ? Icons.notifications_none_rounded
                                      : Icons.notifications_active_outlined,
                                  color: n.isRead
                                      ? AppColors.textDisabled
                                      : palette.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title, style: AppTextStyles.h4),
                                      const SizedBox(height: 2),
                                      Text(
                                        n.body,
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}

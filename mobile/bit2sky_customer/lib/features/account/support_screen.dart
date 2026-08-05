import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/support_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/components.dart';
import '../../widgets/warm_scaffold.dart';

/// Support tickets — list + create.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportProvider);

    return WarmScaffold(
      title: 'Support',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
        backgroundColor: AppColors.teal700,
      ),
      body: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load tickets.')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text('No support tickets',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
                itemBuilder: (_, i) {
                  final t = list[i];
                  return AppCard(
                    onTap: () => context.push('/support/${t.id}'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.subject, style: AppTextStyles.h4),
                              Text('#${t.ticketNumber} · ${t.category}',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        StatusBadge(
                          text: t.status,
                          background: t.isClosed
                              ? AppColors.successLight
                              : AppColors.warningLight,
                          foreground: t.isClosed
                              ? AppColors.successGreen
                              : AppColors.warningOrange,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _createSheet(BuildContext context, WidgetRef ref) {
    final subject = TextEditingController();
    final message = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s16,
            AppSpacing.s16, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New support ticket', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s16),
            TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: AppSpacing.s12),
            TextField(
                controller: message,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Describe your issue')),
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Submit',
              onPressed: () async {
                if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(supportProvider.notifier)
                    .create(subject.text.trim(), 'general', message.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

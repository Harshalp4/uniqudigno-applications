import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/support_provider.dart';
import '../../widgets/warm_scaffold.dart';

/// Support ticket conversation.
class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(dioClientProvider).postData<dynamic>(
          '/support/tickets/${widget.ticketId}/messages', body: {'body': text});
      _input.clear();
      ref.invalidate(ticketMessagesProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(DioClient.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(ticketMessagesProvider(widget.ticketId));

    return WarmScaffold(
      title: 'Ticket',
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Could not load messages.')),
              data: (list) => ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  for (final m in list)
                    Align(
                      alignment: m.isFromAgent
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: m.isFromAgent
                              ? AppColors.surface
                              : AppColors.teal700,
                          border: m.isFromAgent
                              ? Border.all(color: AppColors.borderDefault)
                              : null,
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                        child: Text(m.body,
                            style: AppTextStyles.body.copyWith(
                                color: m.isFromAgent
                                    ? AppColors.textPrimary
                                    : Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'Reply…'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.teal700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_models.dart';
import 'app_providers.dart';

class SupportNotifier extends AsyncNotifier<List<SupportTicket>> {
  @override
  Future<List<SupportTicket>> build() => _load();

  Future<List<SupportTicket>> _load() async {
    try {
      final data = await ref
          .read(dioClientProvider)
          .getData<List<dynamic>>('/support/tickets');
      return data.map((e) => SupportTicket.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> create(String subject, String category, String message) async {
    await ref.read(dioClientProvider).postData<dynamic>('/support/tickets',
        body: {'subject': subject, 'category': category, 'message': message});
    state = AsyncData(await _load());
  }
}

final supportProvider =
    AsyncNotifierProvider<SupportNotifier, List<SupportTicket>>(SupportNotifier.new);

final ticketMessagesProvider =
    FutureProvider.family<List<SupportMessage>, String>((ref, ticketId) async {
  final data = await ref
      .read(dioClientProvider)
      .getData<List<dynamic>>('/support/tickets/$ticketId/messages');
  return data.map((e) => SupportMessage.fromJson(e as Map<String, dynamic>)).toList();
});

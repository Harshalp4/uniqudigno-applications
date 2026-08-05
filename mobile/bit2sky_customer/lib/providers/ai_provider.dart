import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/ai_models.dart';
import 'app_providers.dart';

class AiChatState {
  final String? sessionId;
  final List<AiMessage> messages;
  final bool sending;
  final String? error;

  const AiChatState({
    this.sessionId,
    this.messages = const [],
    this.sending = false,
    this.error,
  });

  AiChatState copyWith({
    String? sessionId,
    List<AiMessage>? messages,
    bool? sending,
    String? error,
  }) =>
      AiChatState(
        sessionId: sessionId ?? this.sessionId,
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        error: error,
      );
}

const _welcome = AiMessage(
  id: 'welcome',
  role: AiRole.assistant,
  content:
      "Hi, I'm Wellio 🤖 — your health copilot. Ask me about your reports, "
      'symptoms, or wellness. I offer general guidance, not a diagnosis.',
);

class AiChatNotifier extends Notifier<AiChatState> {
  DioClient get _dio => ref.read(dioClientProvider);

  @override
  AiChatState build() => const AiChatState(messages: [_welcome]);

  /// Loads the most recent session (or creates one), with its history.
  Future<void> ensureSession() async {
    if (state.sessionId != null) return;
    try {
      final sessions =
          await _dio.getData<List<dynamic>>('/ai/sessions');
      String sessionId;
      List<AiMessage> history = const [];
      if (sessions.isNotEmpty) {
        sessionId = AiSession.fromJson(sessions.first as Map<String, dynamic>).id;
        final msgs = await _dio
            .getData<List<dynamic>>('/ai/sessions/$sessionId/messages');
        history =
            msgs.map((e) => AiMessage.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        final created =
            await _dio.postData<Map<String, dynamic>>('/ai/sessions');
        sessionId = AiSession.fromJson(created).id;
      }
      state = state.copyWith(
        sessionId: sessionId,
        messages: history.isEmpty ? [_welcome] : history,
      );
    } catch (_) {
      // Stay on the local welcome state; first send will retry session creation.
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final userMsg = AiMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        role: AiRole.user,
        content: trimmed);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      sending: true,
      error: null,
    );

    try {
      await ensureSession();
      final sessionId = state.sessionId;
      if (sessionId == null) throw 'No session';
      final data = await _dio.postData<Map<String, dynamic>>(
        '/ai/sessions/$sessionId/message',
        body: {'content': trimmed},
      );
      final reply = AiMessage.fromJson(data);
      state = state.copyWith(
          messages: [...state.messages, reply], sending: false);
    } catch (e) {
      state = state.copyWith(
        sending: false,
        messages: [
          ...state.messages,
          AiMessage(
            id: 'err-${DateTime.now().microsecondsSinceEpoch}',
            role: AiRole.assistant,
            content: e is String && e == 'No session'
                ? 'Please log in to chat with Wellio.'
                : DioClient.errorMessage(e),
          ),
        ],
      );
    }
  }
}

final aiChatProvider =
    NotifierProvider<AiChatNotifier, AiChatState>(AiChatNotifier.new);

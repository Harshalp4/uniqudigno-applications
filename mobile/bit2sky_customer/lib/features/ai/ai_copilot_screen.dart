import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/secure_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/ai_provider.dart';
import '../../widgets/chat_widgets.dart';
import '../../widgets/warm_scaffold.dart';

/// AI Copilot — Wellio (Part 6/Screen9). PHI: screenshot-blocked.
class AiCopilotScreen extends ConsumerStatefulWidget {
  const AiCopilotScreen({super.key});

  @override
  ConsumerState<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends ConsumerState<AiCopilotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(aiChatProvider.notifier).ensureSession());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(aiChatProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(aiChatProvider);
    _scrollToBottom();
    final itemCount = chat.messages.length + (chat.sending ? 1 : 0);

    return SecureScreen(
      child: WarmScaffold(
        title: '🤖 Wellio · Health Copilot',
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                itemCount: itemCount,
                itemBuilder: (context, i) {
                  if (chat.sending && i == chat.messages.length) {
                    return const TypingIndicator();
                  }
                  return ChatBubble(message: chat.messages[i]);
                },
              ),
            ),
            _Composer(controller: _input, onSend: _send, busy: chat.sending),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool busy;
  const _Composer(
      {required this.controller, required this.onSend, required this.busy});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask Wellio anything…',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.teal700,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: busy ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

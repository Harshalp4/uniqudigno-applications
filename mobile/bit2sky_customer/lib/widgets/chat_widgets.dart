import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/ai_models.dart';

/// C21 — AI chat bubble (user = teal right, assistant = white left).
class ChatBubble extends StatelessWidget {
  final AiMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final width = MediaQuery.of(context).size.width;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: width * (isUser ? 0.75 : 0.85)),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.teal700 : AppColors.surface,
        border: isUser ? null : Border.all(color: AppColors.borderDefault),
        boxShadow: isUser ? null : AppShadows.shadow1,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.r16),
          topRight: const Radius.circular(AppRadius.r16),
          bottomLeft: Radius.circular(isUser ? AppRadius.r16 : AppRadius.r4),
          bottomRight: Radius.circular(isUser ? AppRadius.r4 : AppRadius.r16),
        ),
      ),
      child: Text(
        message.content,
        style: AppTextStyles.body
            .copyWith(color: isUser ? Colors.white : AppColors.textPrimary),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}

/// C22 — typing indicator (three bouncing dots in an AI-style bubble).
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.shadow1,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.r16),
              topRight: Radius.circular(AppRadius.r16),
              bottomLeft: Radius.circular(AppRadius.r4),
              bottomRight: Radius.circular(AppRadius.r16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) => _dot(i)),
          ),
        ),
      ),
    );
  }

  Widget _dot(int i) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final phase = (_c.value - i * 0.15) % 1.0;
        final lift = phase < 0.3 ? -6.0 * (phase / 0.3) : 0.0;
        return Transform.translate(
          offset: Offset(0, lift),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.textDisabled, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// C19 — 6-box OTP input with auto-advance and shake-on-error (A28).
class OtpInput extends StatefulWidget {
  final int length;
  final bool error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const OtpInput({
    super.key,
    this.length = 6,
    this.error = false,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didUpdateWidget(covariant OtpInput old) {
    super.didUpdateWidget(old);
    if (widget.error && !old.error) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    widget.onChanged(_value);
    if (_value.length == widget.length) widget.onCompleted(_value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = t == 0 ? 0.0 : 4 * (1 - t) * (t < 0.5 ? -1 : 1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.length; i++) ...[
            _box(i),
            if (i != widget.length - 1) const SizedBox(width: AppSpacing.s8),
          ],
        ],
      ),
    );
  }

  Widget _box(int i) {
    final filled = _controllers[i].text.isNotEmpty;
    final Color border = widget.error
        ? AppColors.errorRed
        : (filled ? AppColors.teal700 : Colors.transparent);
    final Color bg = widget.error
        ? AppColors.errorLight
        : (filled ? AppColors.teal50 : AppColors.surfaceRaised);
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.h3.copyWith(color: AppColors.teal700),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: bg,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            borderSide: BorderSide(color: border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            borderSide: const BorderSide(color: AppColors.teal700, width: 1.5),
          ),
        ),
        onChanged: (v) => _onChanged(i, v),
      ),
    );
  }
}

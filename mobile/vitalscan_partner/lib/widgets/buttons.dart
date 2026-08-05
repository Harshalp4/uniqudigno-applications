import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// C1 — Primary button (52px, teal, scale-on-press, loading state).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          boxShadow: enabled ? AppShadows.primaryButton : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: Colors.white),
                      const SizedBox(width: AppSpacing.s4),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}

/// C2 — Secondary (outlined) button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// Pill CTA (banner / compact actions).
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.background = Colors.white,
    this.foreground = AppColors.teal700,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}

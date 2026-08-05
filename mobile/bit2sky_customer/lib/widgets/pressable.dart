import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Scale-on-press wrapper — THE shared press feedback (redesign Phase 3.3).
/// Scales to 0.97 over [AppMotion.fast] on press-down and springs back with
/// [AppMotion.emphasized]. Zero-duration under reduce-motion.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const Pressable(
      {super.key, required this.child, this.onTap, this.scale = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.of(context, AppMotion.fast),
        curve: _down ? AppMotion.easeOut : AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}

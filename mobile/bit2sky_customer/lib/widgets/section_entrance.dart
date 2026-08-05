import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// One-shot section entrance: fade 0→1 + slide up 12→0 over [AppMotion.base],
/// staggered by [AppMotion.stagger] × [index]. A section animates only the
/// first time it is ever built (keyed by [id]) — scroll-back and rebuilds
/// never re-trigger it. Honors reduce-motion via [AppMotion.of].
class SectionEntrance extends StatefulWidget {
  final String id;
  final int index;
  final Widget child;

  const SectionEntrance({
    super.key,
    required this.id,
    required this.index,
    required this.child,
  });

  static final Set<String> _played = <String>{};

  @override
  State<SectionEntrance> createState() => _SectionEntranceState();
}

class _SectionEntranceState extends State<SectionEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!SectionEntrance._played.contains(widget.id)) {
      SectionEntrance._played.add(widget.id);
      _controller = AnimationController(vsync: this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _controller == null) return;
        _controller!.duration = AppMotion.of(context, AppMotion.base);
        Future.delayed(
          AppMotion.of(context, AppMotion.stagger * widget.index),
          () {
            if (mounted) _controller?.forward();
          },
        );
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child; // already played — static
    final curved =
        CurvedAnimation(parent: controller, curve: AppMotion.easeOut);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

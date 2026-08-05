import 'package:flutter/material.dart';

/// Animated "no image yet" placeholder with a healthcare identity: a soft
/// tinted gradient with an ECG heartbeat trace that draws itself across the
/// tile on a loop (trace reveal + a heart pulse as the beat passes).
///
/// Use anywhere the API may omit an image (category tiles, packages,
/// articles): pass the surface [base] color and the brand [accent]. Under
/// reduce-motion the full trace renders statically — no ambient animation.
class EcgPlaceholder extends StatefulWidget {
  final Color base;
  final Color accent;

  const EcgPlaceholder({super.key, required this.base, required this.accent});

  @override
  State<EcgPlaceholder> createState() => _EcgPlaceholderState();
}

class _EcgPlaceholderState extends State<EcgPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _cycle.stop();
      _cycle.value = 1.0; // static full trace
    } else if (!_cycle.isAnimating) {
      _cycle.repeat();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.base,
            Color.lerp(widget.base, widget.accent, 0.16)!,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _cycle,
        builder: (context, _) => CustomPaint(
          painter: EcgTracePainter(t: _cycle.value, color: widget.accent),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class EcgTracePainter extends CustomPainter {
  /// 0→1 cycle: 0–0.75 the trace draws left → right, 0.75–1 it fades out.
  final double t;
  final Color color;

  const EcgTracePainter({required this.t, required this.color});

  Path _trace(Size s) {
    final midY = s.height * 0.52;
    final w = s.width;
    return Path()
      ..moveTo(0, midY)
      ..lineTo(w * 0.30, midY)
      // Small pre-beat blip.
      ..lineTo(w * 0.35, midY - s.height * 0.06)
      ..lineTo(w * 0.40, midY)
      // QRS spike.
      ..lineTo(w * 0.46, midY + s.height * 0.10)
      ..lineTo(w * 0.53, midY - s.height * 0.30)
      ..lineTo(w * 0.60, midY + s.height * 0.16)
      ..lineTo(w * 0.65, midY)
      // Recovery bump, then flatline out.
      ..quadraticBezierTo(w * 0.73, midY - s.height * 0.10, w * 0.80, midY)
      ..lineTo(w, midY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final reveal = Curves.easeInOut.transform((t / 0.75).clamp(0.0, 1.0));
    final fade = t <= 0.75
        ? 1.0
        : 1.0 - Curves.easeIn.transform(((t - 0.75) / 0.25).clamp(0.0, 1.0));
    if (reveal <= 0 || fade <= 0) return;

    final full = _trace(size);
    final metric = full.computeMetrics().first;
    final visible = metric.extractPath(0, metric.length * reveal);

    // Soft glow pass under the crisp line.
    canvas.drawPath(
      visible,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.18 * fade),
    );
    canvas.drawPath(
      visible,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.85 * fade),
    );

    // Bright beat head riding the end of the visible trace.
    if (reveal < 1.0) {
      final head = metric.getTangentForOffset(metric.length * reveal);
      if (head != null) {
        canvas.drawCircle(
          head.position,
          2.6,
          Paint()..color = color.withValues(alpha: 0.9 * fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant EcgTracePainter old) =>
      old.t != t || old.color != color;
}

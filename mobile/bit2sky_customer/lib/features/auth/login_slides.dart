import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/ecg_placeholder.dart';

/// Login hero carousel slides (wireframe option K): five diagnostic vignettes
/// — DNA helix, report ticking, sample drop, ECG paper, health-score dial —
/// each with its own looping animation and message. Every slide freezes at a
/// meaningful still frame under reduce-motion.

/// Message + tagline anchored near the slide bottom (above the dots).
class _Caption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool light;
  const _Caption(this.title, this.subtitle, {this.light = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 34,
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: light ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                  color: light
                      ? const Color(0xFFAFCBE2)
                      : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Base for slides driven by one repeating controller.
abstract class _LoopSlideState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController loop =
      AnimationController(vsync: this, duration: loopDuration);

  Duration get loopDuration;

  /// Value to freeze at under reduce-motion (a "finished" look).
  double get reducedValue => 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      loop.stop();
      loop.value = reducedValue;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

// ─────────────────────────── 1. DNA HELIX (dark) ───────────────────────────

class DnaHelixSlide extends StatefulWidget {
  const DnaHelixSlide({super.key});
  @override
  State<DnaHelixSlide> createState() => _DnaHelixSlideState();
}

class _DnaHelixSlideState extends _LoopSlideState<DnaHelixSlide> {
  @override
  Duration get loopDuration => const Duration(milliseconds: 3200);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C2238), Color(0xFF123B5C)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: loop,
          builder: (context, _) =>
              CustomPaint(painter: _HelixPainter(t: loop.value)),
        ),
        const _Caption('Decode your health', 'DNA-deep diagnostics',
            light: true),
      ],
    );
  }
}

class _HelixPainter extends CustomPainter {
  final double t;
  const _HelixPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    const rungs = 9;
    final cx = size.width / 2;
    final top = size.height * 0.14;
    final spacing = (size.height * 0.52) / (rungs - 1);
    const radius = 52.0;
    const blue = Color(0xFF5FB4F0);
    const green = Color(0xFF7FE0A5);

    for (var i = 0; i < rungs; i++) {
      final y = top + i * spacing;
      final phase = 2 * math.pi * t + i * 0.55;
      final x = math.sin(phase) * radius;
      final depth = math.cos(phase); // -1..1 — fakes 3D via size/alpha
      final a = 0.45 + 0.55 * ((depth + 1) / 2);

      final p1 = Offset(cx + x, y);
      final p2 = Offset(cx - x, y);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..shader = LinearGradient(colors: [
            blue.withValues(alpha: 0.7 * a),
            green.withValues(alpha: 0.7 * a)
          ]).createShader(Rect.fromPoints(p1, p2))
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(p1, 4.5 + 1.5 * depth.abs(),
          Paint()..color = blue.withValues(alpha: a));
      canvas.drawCircle(p2, 4.5 + 1.5 * depth.abs(),
          Paint()..color = green.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(covariant _HelixPainter old) => old.t != t;
}

// ─────────────────────────── 2. REPORT READY ───────────────────────────

class ReportSlide extends StatefulWidget {
  const ReportSlide({super.key});
  @override
  State<ReportSlide> createState() => _ReportSlideState();
}

class _ReportSlideState extends _LoopSlideState<ReportSlide> {
  @override
  Duration get loopDuration => const Duration(milliseconds: 5000);
  @override
  double get reducedValue => 0.75; // settled: all rows + stamp visible

  static const _rows = [
    ('Hemoglobin', '14.2 g/dL'),
    ('HbA1c', '5.4 %'),
    ('TSH', '2.1 mIU/L'),
  ];

  double _seg(double t, double start, double len) =>
      ((t - start) / len).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFDF9), Color(0xFFF6EDE0)],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.42),
          child: AnimatedBuilder(
            animation: loop,
            builder: (context, _) {
              final t = loop.value;
              final entrance = Curves.easeOut.transform(_seg(t, 0.0, 0.10));
              final fadeOut = t > 0.92 ? 1 - _seg(t, 0.92, 0.08) : 1.0;
              final stamp = Curves.easeOut.transform(_seg(t, 0.62, 0.07));
              final clockK = 0.5 + 0.5 * math.sin(t * math.pi * 6);

              return Opacity(
                opacity: entrance * fadeOut,
                child: Transform.translate(
                  offset: Offset(0, 26 * (1 - entrance)),
                  child: Transform.rotate(
                    angle: -0.035,
                    child: SizedBox(
                      width: 224,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── the report document ──
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x2E273244),
                                    blurRadius: 30,
                                    offset: Offset(0, 14)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Brand accent bar.
                                Container(
                                    height: 5,
                                    color: const Color(0xFF428AC7)),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 12, 14, 14),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Lab header: logo dot + name line.
                                      Row(children: [
                                        Container(
                                            width: 14,
                                            height: 14,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFF428AC7),
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Container(
                                            width: 92,
                                            height: 8,
                                            decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFFD8E4F0),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        4))),
                                      ]),
                                      const SizedBox(height: 7),
                                      // Faint patient-info line.
                                      Container(
                                          width: 130,
                                          height: 6,
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFEDF1F6),
                                              borderRadius:
                                                  BorderRadius.circular(3))),
                                      const SizedBox(height: 10),
                                      const Divider(
                                          height: 1,
                                          color: Color(0xFFE9EDF3)),
                                      const SizedBox(height: 10),
                                      for (var i = 0; i < _rows.length; i++)
                                        _resultRow(i, t),
                                      const SizedBox(height: 2),
                                      // NORMAL stamp.
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Opacity(
                                          opacity: stamp,
                                          child: Transform.rotate(
                                            angle: -0.16,
                                            child: Transform.scale(
                                              scale: 1.7 - 0.7 * stamp,
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFF36B665),
                                                      width: 2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                                child: const Text('NORMAL',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(
                                                            0xFF36B665))),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Folded corner.
                          Positioned(
                            top: 0,
                            right: 0,
                            child: ClipPath(
                              clipper: _FoldClipper(),
                              child: Container(
                                  width: 22,
                                  height: 22,
                                  color: const Color(0xFFE4E9F0)),
                            ),
                          ),
                          // Pulsing "6 hr" clock badge.
                          Positioned(
                            left: -14,
                            top: -14,
                            child: Transform.scale(
                              scale: 1 + 0.06 * clockK,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF428AC7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF428AC7)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 15, color: Colors.white),
                                    Text('6 hr',
                                        style: TextStyle(
                                            fontSize: 8.5,
                                            height: 1.1,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const _Caption('Reports in 6 hours', 'Clear, verified, on time'),
      ],
    );
  }

  Widget _resultRow(int i, double t) {
    final v = Curves.easeOut.transform(_seg(t, 0.14 + i * 0.14, 0.09));
    final tick = Curves.elasticOut.transform(_seg(t, 0.17 + i * 0.14, 0.10));
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(children: [
        Transform.scale(
          scale: tick,
          child: Container(
            width: 15,
            height: 15,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xFFDFF3E7), shape: BoxShape.circle),
            child: const Text('✓',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F7A43))),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(_rows[i].$1,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF44506B))),
        ),
        Opacity(
          opacity: v,
          child: Text(_rows[i].$2,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937))),
        ),
        const SizedBox(width: 6),
        Opacity(
          opacity: v,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
                color: const Color(0xFFDFF3E7),
                borderRadius: BorderRadius.circular(99)),
            child: const Text('Normal',
                style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F7A43))),
          ),
        ),
      ]),
    );
  }
}

/// Top-right folded-corner triangle.
class _FoldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ─────────────────────────── 3. SAMPLE DROP ───────────────────────────

class SampleDropSlide extends StatefulWidget {
  const SampleDropSlide({super.key});
  @override
  State<SampleDropSlide> createState() => _SampleDropSlideState();
}

class _SampleDropSlideState extends _LoopSlideState<SampleDropSlide> {
  static const _red = Color(0xFFE4574F);

  @override
  Duration get loopDuration => const Duration(milliseconds: 2600);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF6F3), Color(0xFFFBEFE7)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: loop,
          builder: (context, _) => CustomPaint(
              painter: _DropPainter(t: loop.value, color: _red)),
        ),
        const _Caption('One drop tells your story', 'Painless home collection'),
      ],
    );
  }
}

class _DropPainter extends CustomPainter {
  final double t;
  final Color color;
  const _DropPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topY = size.height * 0.16;
    final vialTop = size.height * 0.46;
    final vialH = size.height * 0.26;
    const vialW = 56.0;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFB9C4D4);

    // Dropper.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, topY), width: 12, height: 34),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFFC9D4E2));

    // Falling drop: 18%→58% of the cycle.
    final fall = ((t - 0.18) / 0.40).clamp(0.0, 1.0);
    if (t >= 0.18 && t < 0.60) {
      final y = topY + 22 + (vialTop - topY) * Curves.easeIn.transform(fall);
      final path = Path()
        ..moveTo(cx, y - 9)
        ..quadraticBezierTo(cx + 7, y + 1, cx, y + 7)
        ..quadraticBezierTo(cx - 7, y + 1, cx, y - 9);
      canvas.drawPath(path, Paint()..color = color);
    }

    // Vial + liquid level (rises after the drop lands).
    final lvlT = ((t - 0.58) / 0.10).clamp(0.0, 1.0);
    final level = 0.30 + 0.14 * (t < 0.58 ? 0.0 : lvlT);
    final vial = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - vialW / 2, vialTop, vialW, vialH),
      bottomLeft: const Radius.circular(22),
      bottomRight: const Radius.circular(22),
    );
    canvas.save();
    canvas.clipRRect(vial);
    canvas.drawRect(
      Rect.fromLTWH(cx - vialW / 2, vialTop + vialH * (1 - level), vialW,
          vialH * level),
      Paint()..color = color.withValues(alpha: 0.9),
    );
    canvas.restore();
    canvas.drawRRect(vial, rim);

    // Ripple ellipse on impact.
    final ripT = ((t - 0.58) / 0.32).clamp(0.0, 1.0);
    if (t >= 0.58 && ripT < 1.0) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, vialTop + 6),
            width: 40 + 40 * ripT,
            height: 8 + 6 * ripT),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.5 * (1 - ripT)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DropPainter old) => old.t != t;
}

// ─────────────────────────── 4. ECG PAPER ───────────────────────────

class EcgPaperSlide extends StatefulWidget {
  const EcgPaperSlide({super.key});
  @override
  State<EcgPaperSlide> createState() => _EcgPaperSlideState();
}

class _EcgPaperSlideState extends State<EcgPaperSlide>
    with TickerProviderStateMixin {
  static const _red = Color(0xFFE4574F);
  late final AnimationController _trace =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _beat = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _trace.stop();
      _trace.value = 0.7;
      _beat.stop();
    } else {
      if (!_trace.isAnimating) _trace.repeat();
      if (!_beat.isAnimating) _beat.repeat();
    }
  }

  @override
  void dispose() {
    _trace.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _GraphPaperPainter()),
        Align(
          alignment: const Alignment(0, -0.62),
          child: AnimatedBuilder(
            animation: _beat,
            builder: (context, _) {
              final k =
                  (1 - ((_beat.value - 0.12).abs() / 0.10)).clamp(0.0, 1.0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                      scale: 1 + 0.30 * k,
                      child: const Icon(Icons.favorite,
                          color: _red, size: 18)),
                  const SizedBox(width: 6),
                  Text('72 bpm',
                      style: AppTextStyles.captionMed.copyWith(
                          color: _red,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              );
            },
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.05),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _trace,
              builder: (context, _) => CustomPaint(
                  painter: EcgTracePainter(t: _trace.value, color: _red)),
            ),
          ),
        ),
        const _Caption('Your health, our priority', 'Monitored end to end'),
      ],
    );
  }
}

class _GraphPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFDF8));
    final line = Paint()
      ..color = const Color(0xFF428AC7).withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 17) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 17) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPaperPainter old) => false;
}

// ─────────────────────────── 5. HEALTH SCORE ───────────────────────────

class HealthScoreSlide extends StatefulWidget {
  const HealthScoreSlide({super.key});
  @override
  State<HealthScoreSlide> createState() => _HealthScoreSlideState();
}

class _HealthScoreSlideState extends _LoopSlideState<HealthScoreSlide> {
  @override
  Duration get loopDuration => const Duration(seconds: 4);
  @override
  double get reducedValue => 0.6; // arc fully swept

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6FBF7), Color(0xFFEAF6EE)],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.5),
          child: AnimatedBuilder(
            animation: loop,
            builder: (context, _) {
              final sweep = Curves.easeInOut
                  .transform((loop.value / 0.45).clamp(0.0, 1.0));
              final settleK =
                  (1 - ((loop.value - 0.50).abs() / 0.08)).clamp(0.0, 1.0);
              return SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _DialPainter(sweep: sweep)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 1 + 0.12 * settleK,
                            child: Text('82',
                                style: AppTextStyles.h1.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1F7A43))),
                          ),
                          Text('Health Score',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const _Caption('Know your numbers', 'One score, clear trends'),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  final double sweep; // 0..1 → up to 82% of the circle
  const _DialPainter({required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..color = const Color(0xFFDCE8E0));
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * 0.82 * sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [Color(0xFF36B665), Color(0xFF428AC7)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.sweep != sweep;
}

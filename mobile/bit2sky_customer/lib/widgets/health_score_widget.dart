import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'components.dart';

/// Resolves the score label + color by range (Part 5 / C10).
({String label, Color color}) scoreBand(int score) {
  if (score < 40) return (label: 'Poor', color: AppColors.errorRed);
  if (score < 60) return (label: 'Average', color: AppColors.warningOrange);
  if (score < 75) return (label: 'Good', color: AppColors.successGreen);
  if (score < 90) return (label: 'Very Good', color: AppColors.teal700);
  return (label: 'Excellent', color: AppColors.teal800);
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final double stroke;
  _RingPainter(this.progress, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = AppColors.borderDefault
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = AppColors.teal700
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Animated circular gauge with center count-up (C11).
class CircularGauge extends StatelessWidget {
  final int score;
  final double size;
  final double stroke;
  const CircularGauge(
      {super.key, required this.score, this.size = 100, this.stroke = 8});

  @override
  Widget build(BuildContext context) {
    final band = scoreBand(score);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value, stroke),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(value * 100).round()}',
                    style: AppTextStyles.h1.copyWith(color: band.color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// C10 — Home health-score widget.
class HealthScoreWidget extends StatelessWidget {
  final int score;
  final String lastUpdated;
  final VoidCallback? onBreakdown;

  const HealthScoreWidget({
    super.key,
    required this.score,
    this.lastUpdated = '',
    this.onBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final band = scoreBand(score);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$score', style: AppTextStyles.h1),
                        Text(' / 100',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    Text('Your Health Score',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.s4),
                    Text(band.label,
                        style: AppTextStyles.h4.copyWith(color: band.color)),
                    if (lastUpdated.isNotEmpty)
                      Text('Last updated: $lastUpdated',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              CircularGauge(score: score),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onBreakdown,
              child: const Text('View full breakdown →'),
            ),
          ),
        ],
      ),
    );
  }
}

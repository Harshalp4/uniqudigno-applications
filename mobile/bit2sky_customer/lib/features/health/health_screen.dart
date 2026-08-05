import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/secure_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/health_score_widget.dart';
import '../../widgets/pressable.dart';
import '../../widgets/trend_chart.dart';

/// Vitals / Health Score — warm redesign: cream canvas, squiggle title, white
/// gauge card, dashed factor rows, and an actionable empty state.
/// Screenshot-blocked (Section 4D).
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(healthScoreProvider);
    final palette = ref.watch(brandPaletteProvider);

    return SecureScreen(
      child: Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Score',
                        style: AppTextStyles.h1.copyWith(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Your body, summarised from real lab results',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 3),
                    CustomPaint(
                      size: const Size(120, 8),
                      painter: _SquigglePainter(color: palette.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: score.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const _NoScore(),
                  data: (s) =>
                      s == null ? const _NoScore() : _Body(score: s),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final int score;
  const _Body({required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = scoreBand(score);
    final history = ref.watch(healthHistoryProvider).maybeWhen(
        data: (h) => h, orElse: () => const <double>[]);
    final factors = ref.watch(healthFactorsProvider).maybeWhen(
        data: (m) => m, orElse: () => const <String, int>{});

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 110),
      children: [
        // ── gauge card ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, 7)),
            ],
          ),
          child: Column(
            children: [
              CircularGauge(score: score, size: 200, stroke: 15),
              const SizedBox(height: AppSpacing.s8),
              Text(band.label,
                  style: AppTextStyles.h2.copyWith(
                      color: band.color, fontWeight: FontWeight.w800)),
              Text('out of 100',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        if (history.length >= 2) ...[
          const _SquiggleTitle('Your trend'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: TrendChart(values: history),
          ),
        ],
        if (factors.isNotEmpty) ...[
          const _SquiggleTitle('Contributing factors'),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                for (final (i, e) in factors.entries.indexed) ...[
                  if (i > 0) const _DashedLine(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s8),
                    child: Row(
                      children: [
                        Expanded(
                            child:
                                Text(e.key, style: AppTextStyles.h4)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreBand(e.value)
                                .color
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text('${e.value}',
                              style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scoreBand(e.value).color)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NoScore extends StatelessWidget {
  const _NoScore();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🫀', style: TextStyle(fontSize: 44)),
            const SizedBox(height: AppSpacing.s12),
            Text('No health score yet',
                style:
                    AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.s4),
            Text(
                'Book a test — your score builds automatically from your lab results.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s16),
            Pressable(
              onTap: () => context.push('/blood-tests'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3E7FBE), Color(0xFF2C5F94)]),
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text('Book a test',
                    style: AppTextStyles.button.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquiggleTitle extends StatelessWidget {
  final String text;
  const _SquiggleTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(0, AppSpacing.s20, 0, AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: AppTextStyles.h2
                  .copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          const CustomPaint(
            size: Size(110, 8),
            painter: _SquigglePainter(color: Color(0xFF3E7FBE)),
          ),
        ],
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;
  const _SquigglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.23, size.height * 0.7)
      ..lineTo(size.width * 0.30, size.height * 0.2)
      ..lineTo(size.width * 0.37, size.height * 0.8)
      ..lineTo(size.width * 0.43, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SquigglePainter old) => old.color != color;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
                width: 4.5, height: 1.4, color: const Color(0xFFEDE4D3)),
          ),
        );
      },
    );
  }
}

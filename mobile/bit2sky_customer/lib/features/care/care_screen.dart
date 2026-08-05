import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_models.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/health_score_widget.dart';
import '../../widgets/pressable.dart';
import '../auth/login_sheet.dart';
import '../catalogue/select_members_screen.dart';

/// Care tab — the Health Score companion (approved wireframe): score ring +
/// trend, transparent factor chips, "needs attention" cards with an action
/// plan, the care plan (recurring tests + active booking), a why-explained
/// suggestion, and Wellio. Empty/guest states guide toward the first checkup.
class CareScreen extends ConsumerWidget {
  const CareScreen({super.key});

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn =
        ref.watch(authProvider).status == AuthStatus.authenticated;
    final score = ref.watch(healthScoreProvider);
    final name = ref.watch(meProvider).maybeWhen(
        data: (m) => (m?.name?.trim().isNotEmpty ?? false)
            ? m!.name!.split(' ').first
            : null,
        orElse: () => null);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s4),
              child: Row(children: [
                Expanded(
                  child: Text(
                      name == null ? 'Your Care' : "$name's Care",
                      style: AppTextStyles.h1.copyWith(fontSize: 21)),
                ),
                if (loggedIn)
                  Pressable(
                    onTap: () => context.push('/health'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.r100),
                        border: Border.all(
                            color: const Color(0xFFC9BFAD), width: 1.2),
                      ),
                      child: Text('Full report ›',
                          style: AppTextStyles.captionMed.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                  ),
              ]),
            ),
            if (!loggedIn)
              _LoggedOutState(onLogin: () => showLoginSheet(context))
            else
              score.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator())),
                error: (_, _) => const _NoScoreState(),
                data: (s) => s == null
                    ? const _NoScoreState()
                    : _ScoreBody(score: s),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── score body ─────────────────────────

class _ScoreBody extends ConsumerWidget {
  final int score;
  const _ScoreBody({required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final history = ref
        .watch(healthHistoryProvider)
        .maybeWhen(data: (h) => h, orElse: () => const <double>[]);
    final factors = ref
        .watch(healthFactorsProvider)
        .maybeWhen(data: (f) => f, orElse: () => const <String, int>{});
    final band = scoreBand(score);
    final delta = history.length >= 2
        ? (history.last - history[history.length - 2]).round()
        : null;
    final low = factors.entries.where((e) => e.value < 60).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── score card ──
      Container(
        margin: const EdgeInsets.all(AppSpacing.s16),
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 7)),
          ],
        ),
        child: Row(children: [
          CircularGauge(score: score, size: 108, stroke: 11),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(band.label,
                  style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800, color: band.color)),
              if (delta != null && delta != 0) ...[
                const SizedBox(height: 4),
                Text(
                    delta > 0
                        ? '▲ +$delta since your last check'
                        : '▼ $delta since your last check',
                    style: AppTextStyles.captionMed.copyWith(
                        fontWeight: FontWeight.w800,
                        color: delta > 0
                            ? const Color(0xFF1F7A43)
                            : AppColors.errorRed)),
              ],
              if (history.length >= 2) ...[
                const SizedBox(height: 6),
                SizedBox(
                    height: 26,
                    width: double.infinity,
                    child: CustomPaint(
                        painter: _SparklinePainter(
                            history, const Color(0xFF36B665)))),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FB),
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text('📄 From your reports & health checks',
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 9, color: palette.primaryDark)),
              ),
            ]),
          ),
        ]),
      ),

      // ── factor chips ──
      if (factors.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, 0, 8),
          child: Text('What drives your score',
              style: AppTextStyles.h2
                  .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            children: [
              for (final f in factors.entries)
                Container(
                  width: 104,
                  margin: const EdgeInsets.only(right: AppSpacing.s8),
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border(
                        top: BorderSide(
                            width: 3, color: _factorColor(f.value))),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 10,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(f.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                            '${f.value} ${f.value >= 70 ? '✓' : f.value >= 60 ? '' : '↓'}',
                            style: AppTextStyles.body.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _factorColor(f.value))),
                      ]),
                ),
            ],
          ),
        ),
      ],

      // ── needs attention ──
      if (low.isNotEmpty) ...[
        Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, 0, 8),
          child: Text('Needs attention (${low.length})',
              style: AppTextStyles.h2
                  .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
        ),
        for (final f in low.take(2))
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: const Border(
                  left: BorderSide(width: 4, color: Color(0xFFE4574F))),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 14,
                    offset: Offset(0, 5)),
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('${f.key} — below target',
                      style: AppTextStyles.body.copyWith(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE9E4),
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                  child: Text('${f.value}/100',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE4574F))),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                  'Usually improvable in 8–12 weeks. Confirm with a test, adjust, then re-check.',
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      height: 1.4)),
              const SizedBox(height: AppSpacing.s8),
              Row(children: [
                _planChip('🧪 Re-test', const Color(0xFFEAF4FB),
                    const Color(0xFF2F6FA6), () => context.push('/tests')),
                const SizedBox(width: 6),
                _planChip('🥗 Diet consult', const Color(0xFFF0FAF3),
                    const Color(0xFF1F7A43),
                    () => context.push('/services/diet')),
                const SizedBox(width: 6),
                _planChip('🤖 Ask Wellio', const Color(0xFFF6F1FE),
                    const Color(0xFF6D4FC1), () => context.push('/ai')),
              ]),
            ]),
          ),
      ],

      // ── care plan ──
      const _CarePlanSection(),

      // ── suggested ──
      const _SuggestedSection(),

      // ── wellio ──
      Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s4, AppSpacing.s16, 0),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6D4FC1), Color(0xFF4E3691)]),
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Row(children: [
          const Text('🤖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
                'Ask Wellio anything about your reports — in plain language',
                style: AppTextStyles.captionMed.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          Pressable(
            onTap: () => context.push('/ai'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r100),
              ),
              child: Text('Ask',
                  style: AppTextStyles.captionMed.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4E3691))),
            ),
          ),
        ]),
      ),
    ]);
  }

  static Color _factorColor(int v) => v >= 70
      ? const Color(0xFF2A9C54)
      : v >= 60
          ? const Color(0xFFB45D12)
          : const Color(0xFFE4574F);

  Widget _planChip(
      String label, Color bg, Color fg, VoidCallback onTap) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Text(label,
              maxLines: 1,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 9.5, fontWeight: FontWeight.w800, color: fg)),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _SparklinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y =
          size.height - ((points[i] - min) / range) * (size.height - 4) - 2;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points;
}

// ───────────────────────── care plan ─────────────────────────

class _CarePlanSection extends ConsumerWidget {
  const _CarePlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref
        .watch(subscriptionProvider)
        .maybeWhen(data: (s) => s, orElse: () => const []);
    final bookings = ref
        .watch(myBookingsProvider)
        .maybeWhen(data: (b) => b, orElse: () => const <MyBooking>[]);
    final tracked = bookings
        .where((b) => !{'completed', 'cancelled', 'reportready'}
            .contains(b.status.toLowerCase().replaceAll(' ', '')))
        .firstOrNull;
    final active = subs.where((s) => s.status.toLowerCase() == 'active');
    if (active.isEmpty && tracked == null) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, 0, 8),
        child: Text('Your care plan',
            style: AppTextStyles.h2
                .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 5)),
          ],
        ),
        child: Column(children: [
          if (tracked != null)
            Pressable(
              onTap: () => context.push('/orders'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                child: Row(children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 18, color: Color(0xFF2F6FA6)),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text('Active booking in progress',
                        style: AppTextStyles.body.copyWith(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textDisabled),
                ]),
              ),
            ),
          for (final s in active)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Row(children: [
                const Icon(Icons.autorenew_rounded,
                    size: 18, color: Color(0xFF2A9C54)),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recurring · ${s.frequency}',
                            style: AppTextStyles.body.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700)),
                        if (s.nextBookingDate != null)
                          Text('Next: ${s.nextBookingDate}',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                      ]),
                ),
                Pressable(
                  onTap: () => context.push('/subscriptions'),
                  child: Text('Manage ›',
                      style: AppTextStyles.captionMed.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2F6FA6))),
                ),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: AppSpacing.s12),
    ]);
  }
}

// ───────────────────────── suggestion ─────────────────────────

class _SuggestedSection extends ConsumerWidget {
  const _SuggestedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final pkg = (ref.watch(packagesProvider).asData?.value ?? const [])
        .where((p) => p.isFeatured)
        .firstOrNull;
    if (pkg == null) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, 0, 8),
        child: Text('Suggested for you',
            style: AppTextStyles.h2
                .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EE),
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: const Color(0xFFEBD9B4), width: 1),
            ),
            child: Text(
                '🎯 Why this? A full checkup refreshes every factor of your score in one go.',
                style: AppTextStyles.caption.copyWith(
                    fontSize: 10, color: const Color(0xFF8A6A2F))),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(pkg.name,
              style: AppTextStyles.body
                  .copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
          Text('${pkg.testCount} tests',
              style: AppTextStyles.caption
                  .copyWith(fontSize: 10.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            Text('₹${pkg.price}',
                style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.primary)),
            const SizedBox(width: 6),
            if (pkg.mrp > pkg.price)
              Text('₹${pkg.mrp}',
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textDisabled,
                      decoration: TextDecoration.lineThrough)),
            const Spacer(),
            Pressable(
              onTap: () => showPackageMemberSheet(context, pkg.slug),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [palette.primary, palette.primaryDark]),
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text('Book now',
                    style: AppTextStyles.captionMed.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

// ───────────────────────── empty states ─────────────────────────

class _NoScoreState extends StatelessWidget {
  const _NoScoreState();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(AppSpacing.s16),
        padding: const EdgeInsets.all(AppSpacing.s24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        child: Column(children: [
          const Text('💠', style: TextStyle(fontSize: 44)),
          const SizedBox(height: AppSpacing.s12),
          Text('Unlock your Health Score',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.s8),
          Text(
              'Book your first checkup and we turn your lab results into one clear score — with what to fix and how.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5)),
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
              label: 'Book a checkup',
              onPressed: () => context.push('/blood-tests')),
        ]),
      ),
    ]);
  }
}

class _LoggedOutState extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoggedOutState({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s16),
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      child: Column(children: [
        const Text('🔐', style: TextStyle(fontSize: 40)),
        const SizedBox(height: AppSpacing.s12),
        Text('Sign in to see your Health Score',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.s8),
        Text('Your reports, risks and care plan live here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body
                .copyWith(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.s16),
        PrimaryButton(label: 'Login / Sign up', onPressed: onLogin),
      ]),
    );
  }
}

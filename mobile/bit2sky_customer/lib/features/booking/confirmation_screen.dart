import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/booking_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/pressable.dart';

/// Booking confirmation — warm redesign (wireframe A): success burst,
/// keepable booking ticket, "get ready" prep checklist, quick actions, and
/// Go Home / Track Booking.
class ConfirmationScreen extends ConsumerStatefulWidget {
  final bool paid;
  const ConfirmationScreen({super.key, this.paid = false});

  @override
  ConsumerState<ConfirmationScreen> createState() =>
      _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen>
    with TickerProviderStateMixin {
  static const _canvas = Color(0xFFFAF3EA);

  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    _pop.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pop.value = 1;
      _ring.stop();
    } else if (!_ring.isAnimating) {
      _ring.repeat();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _ring.dispose();
    super.dispose();
  }

  /// "07:00" → "7 PM the night before" cutoff (12 hrs earlier).
  String? _fastingCutoff(String? slot) {
    if (slot == null) return null;
    final h = int.tryParse(slot.split(':').first);
    if (h == null) return null;
    final cutoff = (h - 12) % 24;
    if (cutoff == 0) return '12 AM';
    return cutoff > 12 ? '${cutoff - 12} PM' : '$cutoff ${cutoff == 12 ? 'PM' : 'AM'}';
  }

  /// "07:00" → "07:00 – 08:00" arrival window.
  String _window(String slot) {
    final parts = slot.split(':');
    final h = int.tryParse(parts.first);
    if (h == null) return slot;
    final end = (h + 1).toString().padLeft(2, '0');
    return '$slot – $end:${parts.length > 1 ? parts[1] : '00'}';
  }

  Future<void> _copyDetails(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Booking details copied')));
  }

  Future<void> _callSupport() async {
    final phone = ref
        .read(brandingProvider)
        .maybeWhen(data: (b) => b.supportPhone, orElse: () => null);
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Support line coming soon')));
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final result = ref.watch(bookingControllerProvider).asData?.value;
    final uiCtx = ref.watch(lastBookingUiContextProvider);
    final detail = result == null
        ? null
        : ref.watch(bookingDetailProvider(result.bookingId)).asData?.value;

    if (result == null) {
      return const Scaffold(
          backgroundColor: _canvas,
          body: Center(child: Text('No active booking.')));
    }

    final slotTime = uiCtx?.slotTime ?? detail?.scheduledTime;
    final cutoff = _fastingCutoff(slotTime);
    final dateText = detail?.scheduledDate ?? '';
    final patient = detail?.patientName ?? 'You';
    final items = detail?.itemNames.join(' + ') ?? 'Your tests';
    final saved = detail?.discountTotal ?? 0;

    final copyText = 'Booking #${result.bookingNumber}\n'
        '$items\n'
        'For: $patient\n'
        'Date: $dateText ${slotTime ?? ''}\n'
        '${uiCtx?.addressLine ?? ''}\n'
        'Amount: ₹${result.amountPayable}';

    return Scaffold(
      backgroundColor: _canvas,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 64),
          // ── success burst ──
          SizedBox(
            height: 100,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (context, _) {
                      final t = _ring.value;
                      return Transform.scale(
                        scale: 0.7 + t * 0.9,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF7ED6A0)
                                    .withValues(alpha: (1 - t) * 0.9),
                                width: 3),
                          ),
                        ),
                      );
                    },
                  ),
                  ScaleTransition(
                    scale: CurvedAnimation(
                        parent: _pop, curve: Curves.elasticOut),
                    child: Container(
                      width: 78,
                      height: 78,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          Color(0xFF2A9C54),
                          Color(0xFF1F7A42)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x662A9C54),
                              blurRadius: 26,
                              offset: Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 44, color: Colors.white),
                    ),
                  ),
                  const Positioned(
                      left: 60, top: 0, child: Text('🎉')),
                  const Positioned(
                      right: 58, top: 12, child: Text('✨')),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(widget.paid ? 'Booking confirmed!' : 'Booking placed!',
              textAlign: TextAlign.center,
              style: AppTextStyles.h1
                  .copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('#${result.bookingNumber} · SMS & email on their way',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),

          // ── ticket ──
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [palette.primary, palette.primaryDark]),
                  ),
                  child: Row(
                    children: [
                      Text('Sample collection',
                          style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius:
                              BorderRadius.circular(AppRadius.r100),
                        ),
                        child: Text(
                            widget.paid ? 'PAID ✓' : 'PAY AT COLLECTION',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                _TicketRow(
                  emoji: '📅',
                  title: slotTime == null
                      ? dateText
                      : '$dateText · ${_window(slotTime)}',
                  sub: 'Our phlebotomist will arrive in this window',
                ),
                if ((uiCtx?.addressLine ?? '').isNotEmpty) ...[
                  const _TicketDivider(),
                  _TicketRow(
                    emoji: '🏠',
                    title: uiCtx?.addressType ?? 'Address',
                    sub: uiCtx!.addressLine!,
                  ),
                ],
                const _TicketDivider(),
                _TicketRow(
                  emoji: '👤',
                  title: '$patient — $items',
                  sub: 'Report in 6 hrs after the lab receives your sample',
                ),
                const _Perforation(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                  child: Row(
                    children: [
                      Text(
                          widget.paid
                              ? 'Paid online${saved > 0 ? ' · saving ₹${saved.round()}' : ''}'
                              : 'Pay on collection${saved > 0 ? ' · saving ₹${saved.round()}' : ''}',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('₹${result.amountPayable}',
                          style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── prep checklist ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16, AppSpacing.s20, AppSpacing.s16, AppSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get ready for your test',
                    style: AppTextStyles.h2.copyWith(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                CustomPaint(
                  size: const Size(110, 8),
                  painter: _SquigglePainter(color: palette.primary),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 16,
                    offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                if (cutoff != null)
                  _PrepRow('🚫🍽',
                      'Fasting tests? Stop eating by $cutoff the night before'),
                if (cutoff != null) const _TicketDivider(),
                const _PrepRow('💧', 'Water is fine — stay hydrated'),
                const _TicketDivider(),
                const _PrepRow(
                    '💊', 'Ask your doctor before skipping medicines'),
                const _TicketDivider(),
                const _PrepRow(
                    '🪪', 'Keep an ID ready for the phlebotomist'),
              ],
            ),
          ),

          // ── quick actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
            child: Row(
              children: [
                Expanded(
                    child: _ActionTile(
                        emoji: '📋',
                        label: 'Copy details',
                        onTap: () => _copyDetails(copyText))),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                    child: _ActionTile(
                        emoji: '🧾',
                        label: 'My orders',
                        onTap: () => context.push('/orders'))),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                    child: _ActionTile(
                        emoji: '📞',
                        label: 'Need help?',
                        onTap: _callSupport)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0E9DC))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: () => context.go('/home'),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: palette.primary, width: 1.8),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('Go Home',
                        style: AppTextStyles.button.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Pressable(
                  onTap: () => context.go('/orders/${result.bookingId}'),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [palette.primary, palette.primaryDark]),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text('Track Booking →',
                        style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  const _TicketRow(
      {required this.emoji, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                Text(sub,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = ((constraints.maxWidth - 32) / 8).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                  width: 4.5, height: 1.4, color: const Color(0xFFEDE4D3)),
            ),
          ),
        );
      },
    );
  }
}

/// Receipt tear-line with edge notches.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              left: 16, right: 16, top: 8, child: _TicketDividerLine()),
          Positioned(
            left: -9,
            top: 0,
            child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: Color(0xFFFAF3EA), shape: BoxShape.circle)),
          ),
          Positioned(
            right: -9,
            top: 0,
            child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: Color(0xFFFAF3EA), shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

class _TicketDividerLine extends StatelessWidget {
  const _TicketDividerLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 9).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
                width: 5, height: 2, color: const Color(0xFFE3D9C6)),
          ),
        );
      },
    );
  }
}

class _PrepRow extends StatelessWidget {
  final String emoji;
  final String text;
  const _PrepRow(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B5A77))),
          ],
        ),
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

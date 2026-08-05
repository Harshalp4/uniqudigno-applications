import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/pressable.dart';

/// My Bookings — warm redesign (profile wireframe 2): filter chips, active
/// bookings as mini tickets with gradient header + inline progress dots, and
/// compact history rows.
class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  static const _canvas = Color(0xFFFAF3EA);
  int _filter = 0; // 0 all, 1 active, 2 completed

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    final palette = ref.watch(brandPaletteProvider);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text('My Bookings',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
              child: Row(
                children: [
                  for (final (i, label)
                      in const ['All', 'Active', 'Completed'].indexed) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Pressable(
                      onTap: () => setState(() => _filter = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _filter == i
                              ? const Color(0xFFEDF4FB)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.r100),
                          border: Border.all(
                              color: _filter == i
                                  ? palette.primary
                                  : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Text(label,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _filter == i
                                    ? palette.primaryDark
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: bookings.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _OrdersEmpty(),
                data: (list) {
                  final filtered = switch (_filter) {
                    1 => list.where((b) => b.isActive).toList(),
                    2 => list.where((b) => !b.isActive).toList(),
                    _ => list,
                  };
                  if (filtered.isEmpty) return const _OrdersEmpty();
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(myBookingsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (_, i) => filtered[i].isActive
                          ? _TicketCard(
                              booking: filtered[i], palette: palette)
                          : _HistoryRow(booking: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active booking as a mini ticket: gradient header, details, progress dots.
class _TicketCard extends StatelessWidget {
  final MyBooking booking;
  final dynamic palette;
  const _TicketCard({required this.booking, required this.palette});

  static const _stepEmojis = ['✓', '🚗', '💉', '🧪', '📄'];

  @override
  Widget build(BuildContext context) {
    final step = booking.currentStep;
    return Pressable(
      onTap: () => context.push('/orders/${booking.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [palette.primary, palette.primaryDark]),
              ),
              child: Row(
                children: [
                  Text('#${booking.bookingNumber}',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text(booking.status.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        if (i > 0)
                          Expanded(
                            child: Container(
                                height: 2.5,
                                color: i <= step
                                    ? const Color(0xFF2A9C54)
                                    : const Color(0xFFE7DFD2)),
                          ),
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < step
                                ? const Color(0xFF2A9C54)
                                : i == step
                                    ? const Color(0xFFEDF4FB)
                                    : const Color(0xFFF1EBDE),
                            border: i == step
                                ? Border.all(
                                    color: palette.primary, width: 2)
                                : null,
                          ),
                          child: Text(
                              i < step ? '✓' : _stepEmojis[i],
                              style: TextStyle(
                                  fontSize: i < step ? 11 : 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: i < step
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              palette.primary,
                              palette.primaryDark
                            ]),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text('Track live →',
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Completed / cancelled booking as a compact row.
class _HistoryRow extends StatelessWidget {
  final MyBooking booking;
  const _HistoryRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final completed = booking.status == 'Completed';
    return Pressable(
      onTap: () => context.push('/orders/${booking.id}'),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFE9F8EE)
                    : const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(completed ? '✓' : '✕',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: completed
                          ? const Color(0xFF2A9C54)
                          : const Color(0xFFD64541))),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4),
                  Text('#${booking.bookingNumber}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFE9F8EE)
                    : const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(AppRadius.r100),
              ),
              child: Text(booking.status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: completed
                          ? const Color(0xFF2A9C54)
                          : const Color(0xFFD64541))),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 44)),
            const SizedBox(height: AppSpacing.s12),
            Text('No bookings here yet',
                style:
                    AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Your bookings and sample collection status will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

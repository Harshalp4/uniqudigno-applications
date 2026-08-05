import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_provider.dart';
import '../../providers/booking_tracking_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../widgets/booking_tracker.dart';
import '../../widgets/components.dart';
import 'reschedule_sheet.dart';
import '../../widgets/warm_scaffold.dart';

/// P0d — live order tracking: BookingTracker driven by the SignalR hub with
/// a 15s polling fallback, payment chip (COD flips to Paid live), and the
/// P0c Reschedule entry point.
class OrderDetailScreen extends ConsumerWidget {
  final String bookingId;
  const OrderDetailScreen({super.key, required this.bookingId});

  /// 6-stage tracker index (Booking Confirmed · Technician Assigned · On The
  /// Way · Sample Collected · Processing · Report Ready).
  static int _stageFor(String status) => switch (status) {
        'Confirmed' || 'Rescheduled' => 1,
        'TechnicianAssigned' => 2,
        'SampleCollected' || 'InLab' => 4,
        'ReportReady' => 5,
        'Completed' => 6,
        _ => 0,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    // Subscribe to live updates (side effect: refreshes the detail provider).
    ref.watch(bookingTrackingProvider(bookingId));
    final live = ref.watch(bookingTrackingLiveProvider(bookingId));
    final async = ref.watch(bookingDetailProvider(bookingId));
    final booking = async.asData?.value;

    return WarmScaffold(
      title: 'Order details',
      subtitle:
          booking == null ? null : 'Booking #${booking.bookingNumber}',
      body: Column(children: [
        Expanded(
          child: async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? const Center(child: Text('Could not load this booking.'))
              : RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(bookingDetailProvider(bookingId)),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    children: [
                      _HeaderCard(booking: booking, live: live),
                      const SizedBox(height: AppSpacing.s16),
                      if (booking.isCancelled)
                        AppCard(
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  color: AppColors.errorRed),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Text(
                                  'This booking was cancelled.',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.errorRed),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        AppCard(
                          child: BookingTracker(
                            currentIndex: _stageFor(booking.status),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.s16),
                      _AmountCard(booking: booking, palette: palette),
                      if (booking.canReschedule) ...[
                        const SizedBox(height: AppSpacing.s16),
                        OutlinedButton.icon(
                          onPressed: () =>
                              showRescheduleSheet(context, booking.id),
                          icon: Icon(Icons.event_repeat, color: palette.primary),
                          label: Text(
                            'Reschedule'
                            '${booking.rescheduleCount > 0 ? ' (${booking.maxReschedules - booking.rescheduleCount} left)' : ''}',
                            style: AppTextStyles.button
                                .copyWith(color: palette.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: palette.primary),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.s12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ]),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final BookingDetail booking;
  final bool live;
  const _HeaderCard({required this.booking, required this.live});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.itemNames.isEmpty
                      ? 'Your booking'
                      : booking.itemNames.join(' + '),
                  style: AppTextStyles.h3,
                ),
              ),
              // Pending money = amber (money surface); settled = success green
              // (same convention as the confirmation screen's Paid badge).
              booking.isPaid
                  ? const StatusBadge(
                      text: 'Paid',
                      background: AppColors.successLight,
                      foreground: AppColors.successGreen,
                    )
                  : StatusBadge(
                      text: booking.isCod ? 'Pay on collection' : 'Payment pending',
                      background: AppColors.moneyAccentLight,
                      foreground: AppColors.moneyAccentDark,
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '#${booking.bookingNumber} · ${booking.scheduledDate}'
            '${booking.scheduledTime != null ? ' · ${booking.scheduledTime}' : ''}',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (booking.patientName != null) ...[
            const SizedBox(height: 2),
            Text(
              'Patient: ${booking.patientName}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Icon(
                live ? Icons.wifi_tethering : Icons.sync,
                size: 14,
                color: live ? AppColors.successGreen : AppColors.textDisabled,
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                live ? 'Live updates' : 'Checking periodically',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final BookingDetail booking;
  final dynamic palette;
  const _AmountCard({required this.booking, required this.palette});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _row('Items total', booking.itemsTotal),
          if (booking.walletApplied > 0)
            _row('Wallet applied', -booking.walletApplied),
          const Divider(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount payable', style: AppTextStyles.h4),
              Text(
                '₹${booking.amountPayable.toStringAsFixed(booking.amountPayable % 1 == 0 ? 0 : 1)}',
                style: AppTextStyles.priceLarge.copyWith(color: palette.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, num value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            Text(
              '${value < 0 ? '− ' : ''}₹${value.abs().toStringAsFixed(value.abs() % 1 == 0 ? 0 : 1)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
}

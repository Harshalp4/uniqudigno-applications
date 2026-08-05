import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/tech_booking.dart';
import '../providers/bookings_provider.dart';
import '../widgets/biometric_gate.dart';
import '../widgets/buttons.dart';
import '../widgets/components.dart';

/// Booking detail + status update — PHI, so biometric-gated (Section 9).
class BookingDetailScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BiometricGate(
      reason: 'Authenticate to view booking details',
      child: _Body(bookingId: bookingId),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final String bookingId;
  const _Body({required this.bookingId});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  String? _barcode; // scanned sample barcode — required before SampleCollected
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(todaysBookingsProvider).asData?.value ?? [];
    final booking =
        list.where((b) => b.id == widget.bookingId).cast<TechBooking?>().firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('#${booking?.bookingNumber ?? 'Booking'}')),
      body: booking == null
          ? const Center(child: Text('Booking not found.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Scheduled',
                          '${booking.scheduledDate} ${booking.scheduledTime ?? ''}'),
                      _row('Type', booking.collectionType),
                      _row('Tests', '${booking.itemCount}'),
                      _row('Status', booking.status),
                    ],
                  ),
                ),
                if (_isCollectionStep(booking)) ...[
                  const SectionHeader(title: 'Sample collection'),
                  _BarcodeCard(barcode: _barcode, onScan: _scanBarcode),
                ],
                const SizedBox(height: AppSpacing.s16),
                _nextButton(context, booking),
              ],
            ),
    );
  }

  // The next step from the current status is SampleCollected → show the scan card.
  bool _isCollectionStep(TechBooking b) {
    final idx = techStatuses.indexOf(b.status);
    return idx >= 0 &&
        idx < techStatuses.length - 1 &&
        techStatuses[idx + 1] == 'SampleCollected';
  }

  Future<void> _scanBarcode() async {
    // A camera-based scanner would populate this; entry keeps the flow real and
    // testable today. The value is validated + persisted server-side.
    final controller = TextEditingController(text: _barcode);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          top: AppSpacing.s16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.qr_code_scanner, color: AppColors.teal700),
              const SizedBox(width: AppSpacing.s8),
              Text('Scan sample barcode', style: AppTextStyles.h4),
            ]),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Barcode / sample ID',
                hintText: 'e.g. B2S-SMPL-2048',
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Confirm',
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _barcode = result);
    }
  }

  Widget _nextButton(BuildContext context, TechBooking booking) {
    final idx = techStatuses.indexOf(booking.status);
    final next =
        (idx >= 0 && idx < techStatuses.length - 1) ? techStatuses[idx + 1] : null;
    if (next == null) {
      return const Center(child: Text('Collection complete ✓'));
    }

    final needsBarcode = next == 'SampleCollected';
    final blocked = needsBarcode && (_barcode == null || _barcode!.isEmpty);

    return PrimaryButton(
      label: _busy ? 'Updating…' : 'Mark as ${_label(next)}',
      loading: _busy,
      onPressed: blocked
          ? null
          : () async {
              setState(() => _busy = true);
              final ok = await ref.read(statusUpdateProvider).setStatus(
                    booking.id,
                    next,
                    sampleBarcode: needsBarcode ? _barcode : null,
                  );
              if (!context.mounted) return;
              setState(() => _busy = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(ok ? 'Status updated' : 'Could not update status')));
            },
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            Text(v, style: AppTextStyles.h4),
          ],
        ),
      );

  String _label(String s) => switch (s) {
        'TechnicianAssigned' => 'On the way',
        'SampleCollected' => 'Sample collected',
        'InLab' => 'Handed to lab',
        _ => s,
      };
}

/// Shows the scan control and, once captured, the barcode as a confirmation chip.
class _BarcodeCard extends StatelessWidget {
  final String? barcode;
  final VoidCallback onScan;
  const _BarcodeCard({required this.barcode, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final captured = barcode != null && barcode!.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            captured
                ? 'Sample barcode captured. You can now confirm collection.'
                : 'Scan the sample barcode to confirm collection.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (captured)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.teal700, size: 20),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(barcode!,
                        style: AppTextStyles.h4
                            .copyWith(fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s12),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(captured ? 'Re-scan barcode' : 'Scan sample barcode'),
          ),
        ],
      ),
    );
  }
}

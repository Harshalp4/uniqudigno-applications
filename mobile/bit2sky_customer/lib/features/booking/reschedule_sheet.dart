import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/slot_picker.dart';

/// P0c — reschedule bottom sheet: shared SlotPicker + confirm. Server-side
/// failures (slot full, limit reached, window passed) surface verbatim from
/// the envelope message.
Future<void> showRescheduleSheet(BuildContext context, String bookingId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
    ),
    builder: (_) => _RescheduleSheet(bookingId: bookingId),
  );
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  final String bookingId;
  const _RescheduleSheet({required this.bookingId});

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _slotId;
  String? _time;
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final error = await ref.read(bookingControllerProvider.notifier).reschedule(
          widget.bookingId,
          date: _date,
          slotId: _slotId,
          time: _time,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rescheduled')),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s16, AppSpacing.s16,
          AppSpacing.s16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reschedule collection', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.s16),
            SlotPicker(
              date: _date,
              slotId: _slotId,
              onDate: (d) => setState(() {
                _date = d;
                _slotId = null;
                _time = null;
              }),
              onSlot: (id, time) => setState(() {
                _slotId = id;
                _time = time;
              }),
            ),
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Confirm new slot',
              loading: _busy,
              onPressed: _slotId == null ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

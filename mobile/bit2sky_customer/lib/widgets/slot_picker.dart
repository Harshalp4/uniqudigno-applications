import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/booking_provider.dart';
import '../providers/brand_palette_provider.dart';

/// Reusable date + slot picker (extracted from the booking wizard for P0c so
/// the reschedule sheet shares the exact same availability UI). Dates start
/// tomorrow; slots come from `GET /slots?date=` via [slotsProvider].
class SlotPicker extends ConsumerStatefulWidget {
  final DateTime date;
  final String? slotId;
  final void Function(DateTime) onDate;
  final void Function(String id, String time) onSlot;

  const SlotPicker({
    super.key,
    required this.date,
    required this.slotId,
    required this.onDate,
    required this.onSlot,
  });

  @override
  ConsumerState<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends ConsumerState<SlotPicker> {
  int _period = 0; // 0 morning, 1 afternoon, 2 evening
  static const _periods = ['Morning', 'Afternoon', 'Evening'];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final days =
        List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));
    final slotsAsync = ref.watch(slotsProvider(widget.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Pick a date', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (_, i) {
              final d = days[i];
              final on = _sameDay(d, widget.date);
              return GestureDetector(
                onTap: () => widget.onDate(d),
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: on ? palette.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(
                        color:
                            on ? palette.primary : AppColors.borderDefault),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_weekdays[d.weekday - 1],
                          style: AppTextStyles.caption.copyWith(
                              color: on
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('${d.day}',
                          style: AppTextStyles.h3.copyWith(
                              color:
                                  on ? Colors.white : AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text('Pick a time', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            for (var i = 0; i < _periods.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _period = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          _period == i ? palette.tint : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(
                          color: _period == i
                              ? palette.primary
                              : AppColors.borderDefault),
                    ),
                    child: Text(_periods[i],
                        style: AppTextStyles.bodySmall.copyWith(
                            color: _period == i
                                ? palette.primary
                                : AppColors.textPrimary,
                            fontWeight: _period == i
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        slotsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text('Could not load slots.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          data: (slots) {
            final forPeriod =
                slots.where((s) => s.period == _periods[_period]).toList();
            if (forPeriod.isEmpty) {
              return Text('No slots for this time.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary));
            }
            return Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final s in forPeriod)
                  ChoiceChip(
                    label: Text(s.startTime),
                    selected: widget.slotId == s.id,
                    onSelected: s.available
                        ? (_) => widget.onSlot(s.id, s.startTime)
                        : null,
                    selectedColor: palette.tint,
                    labelStyle: TextStyle(
                        color: !s.available
                            ? AppColors.textDisabled
                            : widget.slotId == s.id
                                ? palette.primary
                                : AppColors.textPrimary,
                        decoration: s.available
                            ? null
                            : TextDecoration.lineThrough,
                        fontWeight: widget.slotId == s.id
                            ? FontWeight.w600
                            : FontWeight.w400),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

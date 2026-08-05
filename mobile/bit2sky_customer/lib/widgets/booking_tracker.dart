import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class TrackerStage {
  final String name;
  final IconData icon;
  const TrackerStage(this.name, this.icon);
}

const bookingStages = <TrackerStage>[
  TrackerStage('Booking Confirmed', Icons.check_circle_outline),
  TrackerStage('Technician Assigned', Icons.person_outline),
  TrackerStage('On The Way', Icons.directions_bike_outlined),
  TrackerStage('Sample Collected', Icons.water_drop_outlined),
  TrackerStage('Processing', Icons.science_outlined),
  TrackerStage('Report Ready', Icons.description_outlined),
];

/// C14 — 6-stage vertical booking tracker. [currentIndex] is the active stage.
class BookingTracker extends StatelessWidget {
  final int currentIndex;
  final List<String> timestamps; // optional per-stage text
  const BookingTracker(
      {super.key, required this.currentIndex, this.timestamps = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < bookingStages.length; i++)
          _StageRow(
            stage: bookingStages[i],
            state: i < currentIndex
                ? _StageState.completed
                : (i == currentIndex ? _StageState.current : _StageState.pending),
            isLast: i == bookingStages.length - 1,
            subtitle: i < timestamps.length ? timestamps[i] : null,
          ),
      ],
    );
  }
}

enum _StageState { completed, current, pending }

class _StageRow extends StatelessWidget {
  final TrackerStage stage;
  final _StageState state;
  final bool isLast;
  final String? subtitle;

  const _StageRow({
    required this.stage,
    required this.state,
    required this.isLast,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      _StageState.completed => (AppColors.successGreen, Colors.white),
      _StageState.current => (AppColors.teal700, Colors.white),
      _StageState.pending => (AppColors.borderDefault, AppColors.textDisabled),
    };
    final connectorColor = state == _StageState.completed
        ? AppColors.successGreen
        : AppColors.borderDefault;
    final titleColor = state == _StageState.pending
        ? AppColors.textSecondary
        : AppColors.textPrimary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(
                    state == _StageState.completed ? Icons.check : stage.icon,
                    size: 16,
                    color: fg),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: connectorColor),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.name,
                      style: AppTextStyles.h4.copyWith(color: titleColor)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/report_models.dart';
import 'components.dart';

/// C12 — Parameter row (Report Detail). Abnormal rows get a red left border + tint.
class ParameterRow extends StatelessWidget {
  final ReportParameter param;
  const ParameterRow({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: param.isAbnormal ? const Color(0xFFFFFAFA) : Colors.transparent,
        border: param.isAbnormal
            ? const Border(left: BorderSide(color: AppColors.errorRed, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(param.name, style: AppTextStyles.h4),
                if (param.referenceRange != null)
                  Text('Ref: ${param.referenceRange}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${param.value ?? '-'}${param.unit != null ? ' ${param.unit}' : ''}',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4,
            ),
          ),
          _badge(),
        ],
      ),
    );
  }

  Widget _badge() {
    return switch (param.status) {
      ParamStatus.normal => StatusBadge.normal(),
      ParamStatus.low =>
        const StatusBadge(text: 'Low', background: AppColors.errorLight, foreground: AppColors.errorRed),
      ParamStatus.high => StatusBadge.high(),
      ParamStatus.critical =>
        const StatusBadge(text: 'Critical', background: AppColors.errorLight, foreground: AppColors.errorRed),
      ParamStatus.borderline => StatusBadge.borderline(),
    };
  }
}

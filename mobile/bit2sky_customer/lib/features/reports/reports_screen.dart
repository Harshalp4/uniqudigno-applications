import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/report_models.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/pressable.dart';

/// Reports — warm redesign (profile wireframe 3): document-style cards with a
/// colored accent edge (green ready / orange pending), lab + date line, and a
/// prominent open action. Ownership stays strict server-side.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);

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
                  Text('My Reports',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: reports.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _Empty(),
                data: (list) => list.isEmpty
                    ? const _Empty()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(reportsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.s12),
                          itemBuilder: (_, i) =>
                              _ReportCard(report: list[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final LabReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final ready = report.isReady;
    final accent =
        ready ? const Color(0xFF2A9C54) : const Color(0xFFF58B44);
    final accentBg =
        ready ? const Color(0xFFE9F8EE) : const Color(0xFFFDF3E7);

    return Pressable(
      onTap:
          ready ? () => context.push('/reports/${report.id}') : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(report.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text(
                        ready ? 'READY' : report.status.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                  ),
                ],
              ),
              if (report.labName != null || report.reportDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [report.labName, report.reportDate]
                        .whereType<String>()
                        .join(' · '),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              if (ready) ...[
                const SizedBox(height: AppSpacing.s12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFF3E7FBE),
                            Color(0xFF2C5F94)
                          ]),
                          borderRadius:
                              BorderRadius.circular(AppRadius.r100),
                        ),
                        child: Text('Open report',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Pressable(
                        onTap: () => context.push('/ai'),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF3E7FBE),
                                width: 1.6),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text('🤖 Ask Wellio',
                              style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF2C5F94),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📄', style: TextStyle(fontSize: 44)),
          const SizedBox(height: AppSpacing.s12),
          Text('No reports yet',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.s4),
          Text('Reports appear here ~6 hrs after sample collection.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

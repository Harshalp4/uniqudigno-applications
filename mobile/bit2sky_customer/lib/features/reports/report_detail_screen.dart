import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/dio_client.dart';
import '../../core/security/secure_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/biometric_gate.dart';
import '../../widgets/components.dart';
import '../../widgets/parameter_row.dart';
import '../../widgets/warm_scaffold.dart';

/// Report Detail (Part 6/Screen10) — PHI. Screenshot-blocked + biometric-gated.
class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    // SecureScreen blocks screenshots/recording; BiometricGate blocks access.
    return SecureScreen(
      child: BiometricGate(child: _ReportDetailBody(reportId: reportId)),
    );
  }
}

class _ReportDetailBody extends ConsumerWidget {
  final String reportId;
  const _ReportDetailBody({required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportByIdProvider(reportId));
    final params = ref.watch(reportParametersProvider(reportId));

    return WarmScaffold(
      title: report.maybeWhen(
          data: (r) => r.title, orElse: () => 'Report'),
      body: params.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load this report.')),
        data: (list) {
          final abnormal = list.where((p) => p.isAbnormal).length;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: AppCard(
                  color: abnormal > 0 ? AppColors.errorLight : AppColors.successLight,
                  child: Row(
                    children: [
                      Icon(
                          abnormal > 0
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color: abnormal > 0
                              ? AppColors.errorRed
                              : AppColors.successGreen),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Text(
                          abnormal > 0
                              ? '$abnormal parameter(s) need attention'
                              : 'All parameters are within range',
                          style: AppTextStyles.h4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: 'Parameters'),
              for (var i = 0; i < list.length; i++) ...[
                ParameterRow(param: list[i]),
                if (i != list.length - 1)
                  const Divider(height: 1, indent: AppSpacing.s16),
              ],
              const SizedBox(height: AppSpacing.s24),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _counselling(context, ref),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: const Text('Counselling'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _download(context, ref),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await ref.read(reportDownloadUrlProvider(reportId).future);
      if (url == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Report PDF not available yet')));
        return;
      }
      final opened = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!opened) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Could not open the report')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _counselling(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(dioClientProvider)
          .postData<dynamic>('/reports/$reportId/request-counselling');
      messenger.showSnackBar(
          const SnackBar(content: Text('Counselling requested')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(DioClient.errorMessage(e))));
    }
  }
}

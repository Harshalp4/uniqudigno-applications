import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/report_models.dart';
import 'app_providers.dart';

/// Own + family reports (GET /reports). Empty when unauthenticated.
final reportsProvider = FutureProvider<List<LabReport>>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<List<dynamic>>('/reports');
    return data.map((e) => LabReport.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

final reportByIdProvider =
    FutureProvider.family<LabReport, String>((ref, reportId) async {
  final data = await ref
      .read(dioClientProvider)
      .getData<Map<String, dynamic>>('/reports/$reportId');
  return LabReport.fromJson(data);
});

final reportParametersProvider =
    FutureProvider.family<List<ReportParameter>, String>((ref, reportId) async {
  final data = await ref
      .read(dioClientProvider)
      .getData<List<dynamic>>('/reports/$reportId/parameters');
  return data
      .map((e) => ReportParameter.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Returns a 15-min signed URL for the report PDF (GET /reports/{id}/download).
final reportDownloadUrlProvider =
    FutureProvider.family<String?, String>((ref, reportId) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/reports/$reportId/download');
    return data['url']?.toString();
  } catch (e) {
    throw DioClient.errorMessage(e);
  }
});

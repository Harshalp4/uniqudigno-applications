/// Report models from /reports (PHI — strict ownership server-side).
library;

class LabReport {
  final String id;
  final String title;
  final String status; // Pending | Processing | Ready | Delivered
  final String? labName;
  final String? reportDate;
  final String counsellingStatus;
  final String createdAt;

  const LabReport({
    required this.id,
    required this.title,
    required this.status,
    this.labName,
    this.reportDate,
    this.counsellingStatus = 'NotRequired',
    required this.createdAt,
  });

  bool get isReady => status == 'Ready' || status == 'Delivered';

  factory LabReport.fromJson(Map<String, dynamic> j) => LabReport(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Report').toString(),
        status: (j['status'] ?? 'Pending').toString(),
        labName: j['labName']?.toString(),
        reportDate: j['reportDate']?.toString(),
        counsellingStatus: (j['counsellingStatus'] ?? 'NotRequired').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}

enum ParamStatus { normal, low, high, critical, borderline }

ParamStatus parseParamStatus(String? s) {
  switch (s) {
    case 'Low':
      return ParamStatus.low;
    case 'High':
      return ParamStatus.high;
    case 'Critical':
      return ParamStatus.critical;
    case 'Borderline':
      return ParamStatus.borderline;
    default:
      return ParamStatus.normal;
  }
}

class ReportParameter {
  final String name;
  final String? value;
  final String? unit;
  final String? referenceRange;
  final ParamStatus status;

  const ReportParameter({
    required this.name,
    this.value,
    this.unit,
    this.referenceRange,
    this.status = ParamStatus.normal,
  });

  bool get isAbnormal => status != ParamStatus.normal;

  factory ReportParameter.fromJson(Map<String, dynamic> j) => ReportParameter(
        name: (j['parameterName'] ?? j['name'] ?? '').toString(),
        value: j['value']?.toString(),
        unit: j['unit']?.toString(),
        referenceRange: j['referenceRange']?.toString(),
        status: parseParamStatus(j['status']?.toString()),
      );
}

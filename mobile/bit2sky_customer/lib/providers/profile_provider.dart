import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

class MeProfile {
  final String? name;
  final String mobile;
  final String? email;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? referralCode;
  const MeProfile(
      {this.name,
      required this.mobile,
      this.email,
      this.gender,
      this.dateOfBirth,
      this.referralCode});

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) a--;
    return a < 0 ? null : a;
  }

  /// A health-app patient needs name + sex + DOB + mobile before booking
  /// (login is email-OTP only, so the mobile is captured at profile setup).
  bool get profileComplete =>
      (name?.trim().isNotEmpty ?? false) &&
      (gender?.isNotEmpty ?? false) &&
      dateOfBirth != null &&
      mobile.trim().isNotEmpty;

  factory MeProfile.fromJson(Map<String, dynamic> j) => MeProfile(
        name: j['name']?.toString(),
        mobile: (j['mobile'] ?? '').toString(),
        email: j['email']?.toString(),
        gender: j['gender']?.toString(),
        dateOfBirth: DateTime.tryParse(
            (j['dateOfBirth'] ?? j['date_of_birth'] ?? '').toString()),
        referralCode:
            (j['referralCode'] ?? j['referral_code'])?.toString(),
      );
}

final meProvider = FutureProvider<MeProfile?>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<Map<String, dynamic>>('/users/me');
    return MeProfile.fromJson(data);
  } catch (_) {
    return null;
  }
});

/// Score history oldest→newest for the trend chart (GET /health/score/history).
final healthHistoryProvider = FutureProvider<List<double>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/health/score/history');
    final scores = data
        .map((e) => ((e as Map)['score'] as num?)?.toDouble() ?? 0)
        .toList()
        .reversed
        .toList();
    return scores;
  } catch (_) {
    return const [];
  }
});

/// Latest health score (GET /health/score). Null when none / unauthenticated.
final healthScoreProvider = FutureProvider<int?>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<dynamic>('/health/score');
    if (data is Map && data['score'] != null) return (data['score'] as num).toInt();
    return null;
  } catch (_) {
    return null;
  }
});

/// Per-pillar health-score breakdown from the DB (`HealthScore.BreakdownJson`).
/// Empty when the user has no score — the UI hides the section rather than
/// showing fabricated factor values.
final healthFactorsProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<dynamic>('/health/score');
    if (data is! Map) return const {};
    final raw = data['breakdownJson'] ?? data['breakdown_json'] ?? data['breakdown'];
    if (raw == null) return const {};
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) return const {};
    return decoded.map((k, v) =>
        MapEntry(k.toString(), v is num ? v.toInt() : int.tryParse('$v') ?? 0));
  } catch (_) {
    return const {};
  }
});

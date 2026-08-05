import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// Partner dashboard (GET /partner/dashboard — own data only).
final partnerDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/partner/dashboard');
  } catch (_) {
    return const {'bookings': 0, 'totalCommission': 0};
  }
});

/// Own created bookings (GET /partner/bookings).
final partnerBookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    return await ref.read(dioClientProvider).getData<List<dynamic>>('/partner/bookings');
  } catch (_) {
    return const [];
  }
});

/// Commission ledger (GET /partner/commissions).
final partnerCommissionsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    return await ref.read(dioClientProvider).getData<List<dynamic>>('/partner/commissions');
  } catch (_) {
    return const [];
  }
});

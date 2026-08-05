import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_models.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

/// Unread badge count for the home-header bell. Guests (and any failed call)
/// resolve to 0 so the badge simply hides — no dead UI, no error surface.
final notificationUnreadCountProvider = FutureProvider<int>((ref) async {
  if (ref.watch(authProvider).status != AuthStatus.authenticated) return 0;
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/notifications/unread-count');
    return (data['count'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
        NotificationsController.new);

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    if (ref.watch(authProvider).status != AuthStatus.authenticated) return const [];
    try {
      final data =
          await ref.read(dioClientProvider).getData<List<dynamic>>('/notifications');
      return data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> markRead(String id) async {
    try {
      await ref.read(dioClientProvider).raw.put('/notifications/$id/read');
    } catch (_) {}
    ref.invalidateSelf();
    ref.invalidate(notificationUnreadCountProvider);
  }

  Future<void> markAllRead() async {
    try {
      await ref.read(dioClientProvider).raw.put('/notifications/read-all');
    } catch (_) {}
    ref.invalidateSelf();
    ref.invalidate(notificationUnreadCountProvider);
  }
}

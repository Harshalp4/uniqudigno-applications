import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account_models.dart';
import 'app_providers.dart';

class SubscriptionNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() => _load();

  Future<List<Subscription>> _load() async {
    try {
      final data =
          await ref.read(dioClientProvider).getData<List<dynamic>>('/subscriptions');
      return data.map((e) => Subscription.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> pause(String id) async {
    await ref
        .read(dioClientProvider)
        .raw
        .put('/subscriptions/$id/pause', data: {'until': null});
    state = AsyncData(await _load());
  }

  Future<void> resume(String id) async {
    await ref.read(dioClientProvider).raw.put('/subscriptions/$id/resume');
    state = AsyncData(await _load());
  }

  Future<void> cancel(String id) async {
    await ref.read(dioClientProvider).raw.delete('/subscriptions/$id');
    state = AsyncData(await _load());
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, List<Subscription>>(
        SubscriptionNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account_models.dart';
import 'app_providers.dart';

// ── Wallet (read) ──
final walletProvider = FutureProvider<Wallet?>((ref) async {
  try {
    final data = await ref.read(dioClientProvider).getData<Map<String, dynamic>>('/wallet');
    return Wallet.fromJson(data);
  } catch (_) {
    return null;
  }
});

final walletTxnsProvider = FutureProvider<List<WalletTxn>>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<List<dynamic>>('/wallet/transactions');
    return data.map((e) => WalletTxn.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

final tierBenefitsProvider = FutureProvider<List<MembershipTier>>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<List<dynamic>>('/wallet/tier-benefits');
    return data.map((e) => MembershipTier.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

// ── Family members (CRUD) ──
class FamilyNotifier extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() => _load();

  Future<List<FamilyMember>> _load() async {
    try {
      final data = await ref
          .read(dioClientProvider)
          .getData<List<dynamic>>('/users/me/family');
      return data.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(Map<String, dynamic> body) async {
    await ref.read(dioClientProvider).postData<dynamic>('/users/me/family', body: body);
    state = AsyncData(await _load());
  }

  Future<void> remove(String id) async {
    await ref.read(dioClientProvider).raw.delete('/users/me/family/$id');
    state = AsyncData(await _load());
  }
}

final familyProvider =
    AsyncNotifierProvider<FamilyNotifier, List<FamilyMember>>(FamilyNotifier.new);

// ── Addresses (CRUD) ──
class AddressNotifier extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() => _load();

  Future<List<Address>> _load() async {
    try {
      final data = await ref
          .read(dioClientProvider)
          .getData<List<dynamic>>('/users/me/addresses');
      return data.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(Map<String, dynamic> body) async {
    await ref.read(dioClientProvider).postData<dynamic>('/users/me/addresses', body: body);
    state = AsyncData(await _load());
  }

  Future<void> remove(String id) async {
    await ref.read(dioClientProvider).raw.delete('/users/me/addresses/$id');
    state = AsyncData(await _load());
  }

  Future<void> setDefault(String id) async {
    await ref
        .read(dioClientProvider)
        .postData<dynamic>('/users/me/addresses/$id/set-default');
    state = AsyncData(await _load());
  }
}

final addressProvider =
    AsyncNotifierProvider<AddressNotifier, List<Address>>(AddressNotifier.new);

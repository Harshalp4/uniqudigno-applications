import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/cart_models.dart';
import 'app_providers.dart';
import 'auth_provider.dart';
import 'guest_cart_provider.dart';

/// Owns the cart. Guests use a local cart (no login to add); signed-in users use
/// the server cart (`/cart`). On login the guest cart is merged server-side.
class CartNotifier extends AsyncNotifier<CartSummary?> {
  DioClient get _dio => ref.read(dioClientProvider);

  bool get _loggedIn =>
      ref.read(authProvider).status == AuthStatus.authenticated;

  @override
  Future<CartSummary?> build() async {
    // Signed in → server cart; guest → derive from the local cart (reactive).
    if (ref.watch(authProvider).status == AuthStatus.authenticated) {
      return _fetchServer();
    }
    return _guestSummary(ref.watch(guestCartProvider));
  }

  Future<CartSummary?> _fetchServer() async {
    try {
      final data = await _dio.getData<Map<String, dynamic>>('/cart');
      return CartSummary.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  CartSummary _guestSummary(List<CartItem> items) {
    // Same semantics as the server summary: itemsTotal = sum of selling
    // prices; discount = MRP savings on top (so MRP total = itemsTotal +
    // discount everywhere).
    final mrpTotal = items.fold<num>(0, (s, i) => s + i.mrp);
    final priceTotal = items.fold<num>(0, (s, i) => s + i.price);
    return CartSummary(
      cartId: 'guest',
      items: items,
      itemsTotal: priceTotal,
      discount: mrpTotal - priceTotal,
      walletApplied: 0,
      payable: priceTotal,
    );
  }

  /// Posts a cart mutation. On success the fresh summary replaces the state;
  /// on failure the CURRENT cart is kept (no error flash, no vanished badge)
  /// and the user-facing message is returned for the caller to surface.
  Future<String?> _post(String path, Map<String, dynamic> body) async {
    try {
      final data = await _dio.postData<Map<String, dynamic>>(path, body: body);
      state = AsyncData(CartSummary.fromJson(data));
      return null;
    } catch (e) {
      return DioClient.errorMessage(e);
    }
  }

  /// Returns null on success or a user-facing error message.
  Future<String?> addTest(
      {required String id,
      required String name,
      required num mrp,
      required num price,
      String? familyMemberId}) async {
    if (!_loggedIn) {
      ref.read(guestCartProvider.notifier).add(CartItem(
          id: GuestCartNotifier.testKey(id),
          testId: id,
          itemName: name,
          mrp: mrp,
          price: price));
      return null; // build() rebuilds via the guestCart watch
    }
    return _post('/cart/items', {
      'testId': id,
      'familyMemberId': ?familyMemberId,
    });
  }

  /// Returns null on success or a user-facing error message.
  Future<String?> addPackage(
      {required String id,
      required String name,
      required num mrp,
      required num price,
      String? familyMemberId}) async {
    if (!_loggedIn) {
      ref.read(guestCartProvider.notifier).add(CartItem(
          id: GuestCartNotifier.packageKey(id),
          packageId: id,
          itemName: name,
          mrp: mrp,
          price: price));
      return null;
    }
    return _post('/cart/items', {
      'packageId': id,
      'familyMemberId': ?familyMemberId,
    });
  }

  /// Applies a coupon code. Returns null on success or a user-facing error
  /// message (state keeps the current cart on failure — no error flash).
  Future<String?> applyCoupon(String code) async {
    if (!_loggedIn) return 'Log in to use coupons';
    try {
      final data = await _dio
          .postData<Map<String, dynamic>>('/cart/coupon', body: {'code': code});
      state = AsyncData(CartSummary.fromJson(data));
      return null;
    } catch (e) {
      return DioClient.errorMessage(e);
    }
  }

  Future<void> removeCoupon() async {
    if (!_loggedIn) return;
    try {
      final data =
          await _dio.raw.delete('/cart/coupon').then((r) => r.data);
      final unwrapped =
          data is Map && data.containsKey('data') ? data['data'] : data;
      state =
          AsyncData(CartSummary.fromJson(unwrapped as Map<String, dynamic>));
    } catch (_) {}
  }

  /// Applies wallet points to the server cart ("use my wallet" = send the
  /// full balance; the server clamps to the redemption cap + real balance and
  /// the returned summary shows what was actually applied). 0 removes them.
  Future<void> applyWalletPoints(num points) async {
    if (!_loggedIn) return; // wallet requires an account
    await _post('/cart/wallet-points', {'points': points});
  }

  /// Returns null on success or a user-facing error message; the current
  /// cart stays visible on failure.
  Future<String?> removeItem(String itemId) async {
    if (!_loggedIn) {
      ref.read(guestCartProvider.notifier).remove(itemId);
      return null;
    }
    try {
      final data =
          await _dio.raw.delete('/cart/items/$itemId').then((r) => r.data);
      final unwrapped =
          data is Map && data.containsKey('data') ? data['data'] : data;
      state = AsyncData(CartSummary.fromJson(unwrapped as Map<String, dynamic>));
      return null;
    } catch (e) {
      return DioClient.errorMessage(e);
    }
  }

  /// Pushes the local guest cart to the server after login.
  /// Call once the user is authenticated (e.g. from the checkout login sheet).
  ///
  /// Each item is only removed from the local cart once it has merged
  /// successfully, so a failed POST (offline / 5xx) never silently drops the
  /// item — it stays in the guest cart to retry. The returned [CartMergeResult]
  /// lets the caller tell the user if any item didn't sync.
  Future<CartMergeResult> mergeGuestCartToServer() async {
    final items = ref.read(guestCartProvider);
    var failed = 0;
    for (final it in items) {
      try {
        await _dio.postData<Map<String, dynamic>>('/cart/items',
            body: it.testId != null
                ? {'testId': it.testId}
                : {'packageId': it.packageId});
        // Merged OK → drop just this item so failures aren't lost on clear().
        ref.read(guestCartProvider.notifier).remove(it.id);
      } catch (_) {
        failed++; // keep it in the guest cart; do not clear unconditionally
      }
    }
    await refresh();
    return CartMergeResult(merged: items.length - failed, failed: failed);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchServer());
  }
}

/// Outcome of [CartNotifier.mergeGuestCartToServer]. [failed] > 0 means some
/// items are still in the local guest cart and were not synced to the server.
class CartMergeResult {
  final int merged;
  final int failed;
  const CartMergeResult({required this.merged, required this.failed});
  bool get hasFailures => failed > 0;
}

final cartProvider =
    AsyncNotifierProvider<CartNotifier, CartSummary?>(CartNotifier.new);

/// Test ids currently in the cart (drives the "Added" state on cards).
final cartTestIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(cartProvider).maybeWhen(
        data: (c) => c?.testIds ?? const {},
        orElse: () => const {},
      );
});


/// Live coupon offers for the checkout chips + sheet — GET /coupons.
final availableCouponsProvider = FutureProvider<List<CouponOffer>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/coupons');
    return data
        .map((e) => CouponOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

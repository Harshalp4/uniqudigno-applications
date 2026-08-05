import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cart_models.dart';

/// Local, on-device cart for guests (no login required to add tests/packages).
/// On login the items are merged into the server cart (see [CartNotifier]).
///
/// Persisted to a Hive box so the cart survives an app restart before login.
/// Contents are catalogue data only (test/package id, name, price) — no PHI —
/// so a plain (unencrypted) box is appropriate.
class GuestCartNotifier extends Notifier<List<CartItem>> {
  static const _boxName = 'guest_cart';
  static const _key = 'items';
  Box? _box;

  @override
  List<CartItem> build() {
    // Hydrate asynchronously; state starts empty and updates once the box loads.
    _hydrate();
    return const [];
  }

  Future<void> _hydrate() async {
    try {
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      final raw = _box!.get(_key);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          state = decoded
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (_) {
      // best-effort persistence; a load failure just yields an empty guest cart
    }
  }

  void _persist() {
    try {
      _box?.put(_key, jsonEncode(state.map((i) => i.toJson()).toList()));
    } catch (_) {
      // best-effort; never block cart updates on a storage error
    }
  }

  static String testKey(String testId) => 't_$testId';
  static String packageKey(String packageId) => 'p_$packageId';

  void add(CartItem item) {
    if (state.any((i) => i.id == item.id)) return; // already in cart
    state = [...state, item];
    _persist();
  }

  void remove(String id) {
    state = state.where((i) => i.id != id).toList();
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final guestCartProvider =
    NotifierProvider<GuestCartNotifier, List<CartItem>>(GuestCartNotifier.new);

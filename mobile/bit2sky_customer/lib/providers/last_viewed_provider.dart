import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// One recently-viewed catalogue entry (D2 "Last viewed" rail). Client-side
/// only — catalogue data (name/slug/price), no PHI, so a plain box is fine.
class LastViewedItem {
  final String type; // 'test' | 'package'
  final String slug;
  final String name;
  final num price;
  final num? mrp;
  final DateTime viewedAt;

  const LastViewedItem({
    required this.type,
    required this.slug,
    required this.name,
    required this.price,
    this.mrp,
    required this.viewedAt,
  });

  String get key => '${type}_$slug';

  Map<String, dynamic> toJson() => {
        'type': type,
        'slug': slug,
        'name': name,
        'price': price,
        'mrp': mrp,
        'viewedAt': viewedAt.toIso8601String(),
      };

  factory LastViewedItem.fromJson(Map<String, dynamic> j) => LastViewedItem(
        type: (j['type'] ?? 'test').toString(),
        slug: (j['slug'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        price: (j['price'] as num?) ?? 0,
        mrp: j['mrp'] as num?,
        viewedAt: DateTime.tryParse((j['viewedAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Local browsing history: most-recent-first, deduped by type+slug, capped.
/// `record` is called from test/package detail screens; the home rail hides
/// while the history is empty.
class LastViewedNotifier extends Notifier<List<LastViewedItem>> {
  static const _boxName = 'last_viewed';
  static const _key = 'items';
  static const _maxEntries = 10;
  Box? _box;

  @override
  List<LastViewedItem> build() {
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
              .map((e) =>
                  LastViewedItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (_) {
      // best-effort persistence; failure just yields an empty history
    }
  }

  void _persist() {
    try {
      _box?.put(_key, jsonEncode(state.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  void record(LastViewedItem item) {
    state = [
      item,
      ...state.where((i) => i.key != item.key),
    ].take(_maxEntries).toList();
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final lastViewedProvider =
    NotifierProvider<LastViewedNotifier, List<LastViewedItem>>(
        LastViewedNotifier.new);

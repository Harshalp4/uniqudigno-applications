import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/deep_link_validator.dart';

/// Shared deep-link navigation for DB-driven home sections: one allowlist
/// (the router's [DeepLinkValidator]) instead of per-widget copies, so new
/// routes work everywhere the moment they're registered + allowlisted.
void navigateDeepLink(BuildContext context, String? deepLink) {
  final link = deepLink?.trim() ?? '';
  if (link.isNotEmpty && DeepLinkValidator.isAllowed(link)) {
    context.push(link);
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

/// Payload list helper: `config['items']` → typed maps (empty on any shape
/// mismatch, so malformed payloads hide the section instead of crashing).
List<Map<String, dynamic>> configItems(Map<String, dynamic> config,
    [String key = 'items']) {
  final raw = config[key];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_models.dart';
import 'app_providers.dart';

/// Editorial rail content (D2). Hidden when empty — no fabricated articles.
final articlesProvider = FutureProvider<List<Article>>((ref) async {
  try {
    final data =
        await ref.read(dioClientProvider).getData<List<dynamic>>('/articles');
    return data.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

final articleDetailProvider = FutureProvider.family<Article?, String>((ref, slug) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/articles/$slug');
    return Article.fromJson(data);
  } catch (_) {
    return null;
  }
});

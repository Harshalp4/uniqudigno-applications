import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalogue_models.dart';
import 'app_providers.dart';

const _networkPatience = Duration(seconds: 4);

/// Tests list with optional search (GET /tests?q=).
final testsProvider = FutureProvider.family<List<Test>, String?>((
  ref,
  query,
) async {
  // Full menu: the real catalogue is ~99 tests; 50 silently hid half of it.
  final params = <String, dynamic>{'pageSize': 200};
  if (query != null && query.isNotEmpty) params['q'] = query;
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/tests', query: params)
        .timeout(_networkPatience);
    return data.map((e) => Test.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return _filterTests(query);
  }
});

/// Popular tests (GET /tests/popular) — feeds the rotating search placeholder
/// and any "popular" rails. Empty on failure (callers hide, never fabricate).
final popularTestsProvider = FutureProvider<List<Test>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/tests/popular')
        .timeout(_networkPatience);
    return data.map((e) => Test.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

/// Personalised "Recommended for You" (GET /tests/recommended). The server
/// tailors it to the signed-in user and returns a popularity default otherwise;
/// the UI falls back to a sample list only when the API is unreachable.
final recommendedTestsProvider = FutureProvider<List<Test>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/tests/recommended', query: {'take': 6})
        .timeout(_networkPatience);
    return data.map((e) => Test.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return _sampleTests.take(6).toList();
  }
});

/// Package filter categories (the home-chip master) — GET /categories?type=Package.
/// Empty on failure; the carousel then shows only the Popular chip.
final packageCategoriesProvider =
    FutureProvider<List<CatalogueCategory>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/categories', query: {'type': 'Package'})
        .timeout(_networkPatience);
    return data
        .map((e) => CatalogueCategory.fromJson(e as Map<String, dynamic>))
        .where((c) => c.showInFilter)
        .toList();
  } catch (_) {
    return const [];
  }
});

final packagesProvider = FutureProvider<List<Package>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/packages', query: {'pageSize': 50})
        .timeout(_networkPatience);
    return data
        .map((e) => Package.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    // No fabricated cards — the catalogue is DB-driven. On failure the carousel
    // self-hides (it treats an empty list as "nothing to show") rather than
    // resurrecting hardcoded/deactivated packages.
    return const <Package>[];
  }
});

/// Category landing (tap Heart / Diabetes / Women's Care) — GET /browse/{slug}.
/// autoDispose so each visit re-fetches (edits/deactivations reflect on return).
final categoryLandingProvider =
    FutureProvider.autoDispose.family<CategoryLanding?, String>((ref, slug) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/browse/$slug')
        .timeout(_networkPatience);
    return CategoryLanding.fromJson(data);
  } catch (_) {
    return null;
  }
});

/// Full package detail incl. bundled tests — GET /packages/{slug}.
/// autoDispose so re-opening the screen re-fetches: admin edits (tests,
/// description) and deactivations show up on the next visit, not just after a
/// full app restart.
final packageDetailProvider =
    FutureProvider.autoDispose.family<PackageDetail?, String>((ref, slug) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/packages/$slug')
        .timeout(_networkPatience);
    return PackageDetail.fromJson(data);
  } catch (_) {
    return null;
  }
});

final testDetailProvider = FutureProvider.family<Test, String>((
  ref,
  slug,
) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/tests/$slug')
        .timeout(_networkPatience);
    return Test.fromJson(data);
  } catch (_) {
    return _sampleTests.firstWhere(
      (t) => t.slug == slug,
      orElse: () => _sampleTests.first,
    );
  }
});

final testParametersProvider =
    FutureProvider.family<List<TestParameter>, String>((ref, testId) async {
      try {
        final data = await ref
            .read(dioClientProvider)
            .getData<List<dynamic>>('/tests/$testId/parameters')
            .timeout(_networkPatience);
        return data
            .map((e) => TestParameter.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return const [
          TestParameter(
            name: 'Hemoglobin',
            unit: 'g/dL',
            referenceRange: '13.0 - 17.0',
          ),
          TestParameter(
            name: 'Total WBC Count',
            unit: '/cumm',
            referenceRange: '4000 - 11000',
          ),
          TestParameter(
            name: 'Platelet Count',
            unit: 'lakh/cumm',
            referenceRange: '1.5 - 4.5',
          ),
        ];
      }
    });

List<Test> _filterTests(String? query) {
  final q = query?.trim().toLowerCase();
  if (q == null || q.isEmpty) return _sampleTests;
  return _sampleTests
      .where(
        (t) =>
            t.name.toLowerCase().contains(q) ||
            (t.shortDescription ?? '').toLowerCase().contains(q),
      )
      .toList();
}

const _sampleTests = [
  Test(
    id: 'sample-cbc',
    name: 'CBC (Complete Blood Count)',
    slug: 'cbc-complete-blood-count',
    shortDescription:
        'Screens red cells, white cells, platelets, and infection markers.',
    mrp: 599,
    price: 299,
    parameterCount: 18,
    reportTimeText: 'Report in 6h',
    isPopular: true,
    ratingAverage: 4.8,
  ),
  Test(
    id: 'sample-thyroid',
    name: 'Thyroid Profile Total',
    slug: 'thyroid-profile-total',
    shortDescription: 'Checks T3, T4, and TSH for thyroid function.',
    mrp: 699,
    price: 349,
    parameterCount: 3,
    reportTimeText: 'Report in 12h',
    isPopular: true,
    ratingAverage: 4.7,
  ),
  Test(
    id: 'sample-lipid',
    name: 'Lipid Profile',
    slug: 'lipid-profile',
    shortDescription:
        'Measures cholesterol, triglycerides, HDL, LDL, and heart risk markers.',
    mrp: 899,
    price: 449,
    parameterCount: 9,
    reportTimeText: 'Report in 12h',
    isPopular: true,
    ratingAverage: 4.8,
  ),
  Test(
    id: 'sample-liver',
    name: 'Liver Function Test',
    slug: 'liver-function-test',
    shortDescription:
        'Checks liver enzymes, bilirubin, proteins, and inflammation markers.',
    mrp: 999,
    price: 499,
    parameterCount: 12,
    reportTimeText: 'Report in 24h',
    isPopular: true,
    ratingAverage: 4.7,
  ),
  Test(
    id: 'sample-hba1c',
    name: 'HbA1c',
    slug: 'hba1c',
    shortDescription: 'Tracks average blood sugar over the last 2-3 months.',
    mrp: 650,
    price: 325,
    parameterCount: 1,
    reportTimeText: 'Report in 12h',
    isPopular: true,
    ratingAverage: 4.9,
  ),
  Test(
    id: 'sample-vitamin-d',
    name: 'Vitamin D Total',
    slug: 'vitamin-d-total',
    shortDescription:
        'Measures Vitamin D level for bone, muscle, and immunity health.',
    mrp: 1299,
    price: 649,
    parameterCount: 1,
    reportTimeText: 'Report in 24h',
    isPopular: false,
    ratingAverage: 4.6,
  ),
];


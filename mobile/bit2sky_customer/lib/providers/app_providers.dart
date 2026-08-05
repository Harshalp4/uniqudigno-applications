import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/storage/encrypted_cache.dart';
import '../models/branding_config.dart';
import '../models/content_models.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

/// Encrypted offline cache. Null until overridden in main() (e.g. in tests).
final encryptedCacheProvider = Provider<EncryptedCache?>((ref) => null);

const _configTtl = Duration(hours: 24);
const _configNetworkPatience = Duration(seconds: 2);

/// Fetches [path], caches the raw JSON, and falls back to a fresh-enough cached
/// copy when the network is unavailable (Section 4D — encrypted offline cache).
Future<T?> _cachedFetch<T>(
  Ref ref,
  String cacheKey,
  String path, {
  Map<String, dynamic>? query,
}) async {
  final cache = ref.read(encryptedCacheProvider);
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<T>(path, query: query)
        .timeout(_configNetworkPatience);
    await cache?.write(cacheKey, data, _configTtl);
    return data;
  } catch (_) {
    final cached = cache?.read(cacheKey);
    return cached is T ? cached : null;
  }
}

final brandingProvider = FutureProvider<BrandingConfig>((ref) async {
  final data = await _cachedFetch<Map<String, dynamic>>(
    ref,
    'config:branding',
    '/config/branding',
  );
  return data == null ? BrandingConfig.fallback : BrandingConfig.fromJson(data);
});

final featureFlagsProvider = FutureProvider<Map<String, String?>>((ref) async {
  final data = await _cachedFetch<Map<String, dynamic>>(
    ref,
    'config:features',
    '/config/features',
  );
  if (data == null) return const {};
  return data.map((k, v) => MapEntry(k, v?.toString()));
});

bool featureEnabled(Map<String, String?> flags, String key) =>
    (flags[key] ?? 'false').toLowerCase() == 'true';

final homeSectionsProvider = FutureProvider<List<HomeSection>>((ref) async {
  final data = await _cachedFetch<List<dynamic>>(
    ref,
    'home:layout',
    '/home/layout',
  );
  if (data == null) return _fallbackSections;
  final list =
      data.map((e) => HomeSection.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return list.isEmpty ? _fallbackSections : list;
});

final quickActionsProvider = FutureProvider<List<QuickAction>>((ref) async {
  final data = await _cachedFetch<List<dynamic>>(
    ref,
    'home:quick-actions',
    '/home/quick-actions',
  );
  if (data == null) return _fallbackQuickActions;
  final list = data
      .map((e) => QuickAction.fromJson(e as Map<String, dynamic>))
      .toList();
  return list.isEmpty ? _fallbackQuickActions : list;
});

final bannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  final data = await _cachedFetch<List<dynamic>>(
    ref,
    'home:banners',
    '/banners',
  );
  if (data == null) return _fallbackBanners;
  final list = data
      .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
      .toList();
  return list.isEmpty ? _fallbackBanners : list;
});

final navItemsProvider = FutureProvider<List<NavItem>>((ref) async {
  final data = await _cachedFetch<List<dynamic>>(
    ref,
    'nav:bottom',
    '/nav/bottom',
  );
  if (data == null) return _fallbackNav;
  final list = data
      .map((e) => NavItem.fromJson(e as Map<String, dynamic>))
      .toList();
  return list.isEmpty ? _fallbackNav : list;
});

// ── Fallbacks (used when both network and cache are unavailable) ──
// 4-tab D2 nav: Reports folds into Profile + Care; '/health' is labeled Vitals.
const _fallbackNav = [
  NavItem(label: 'Home', iconUrl: 'home', route: '/home'),
  NavItem(label: 'Care', iconUrl: 'favorite', route: '/care'),
  NavItem(label: 'Vitals', iconUrl: 'monitor_heart', route: '/health'),
  NavItem(label: 'Profile', iconUrl: 'person', route: '/profile'),
];

const _fallbackQuickActions = [
  QuickAction(id: '1', label: 'Blood Tests', iconUrl: '🩸', deepLink: '/tests'),
  QuickAction(
    id: '2',
    label: 'Full Body',
    iconUrl: '📦',
    deepLink: '/packages',
  ),
  QuickAction(
    id: '3',
    label: 'MRI & Scans',
    iconUrl: '🧲',
    deepLink: '/services/mri',
  ),
  QuickAction(
    id: '4',
    label: 'Doctor Consult',
    iconUrl: '👨‍⚕️',
    deepLink: '/services/doctor',
  ),
  QuickAction(
    id: '5',
    label: 'Diet Consult',
    iconUrl: '🥗',
    deepLink: '/services/diet',
  ),
  QuickAction(
    id: '6',
    label: 'Vaccination',
    iconUrl: '💉',
    deepLink: '/services/vaccination',
  ),
  QuickAction(id: '7', label: 'Reports', iconUrl: '📄', deepLink: '/reports'),
  QuickAction(
    id: '8',
    label: 'Corporate',
    iconUrl: '🏢',
    deepLink: '/services/corporate',
  ),
];

const _fallbackBanners = [
  HomeBanner(
    title: 'Full Body Checkup',
    subtitle: '58 tests at ₹599 · Save 76%',
    ctaLabel: 'Book Now',
    imageUrl:
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&q=80&auto=format&fit=crop',
    deepLink: '/tests',
  ),
  HomeBanner(
    title: 'Free Home Collection',
    subtitle: 'On orders above ₹499',
    ctaLabel: 'Explore',
    imageUrl:
        'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=900&q=80&auto=format&fit=crop',
    deepLink: '/tests',
  ),
  HomeBanner(
    title: 'Family Health Plans',
    subtitle: 'Cover up to 6 members',
    ctaLabel: 'View Plans',
    imageUrl:
        'https://images.unsplash.com/photo-1511174511562-5f7f18b874f8?w=900&q=80&auto=format&fit=crop',
    deepLink: '/packages',
  ),
];

// Offline skeleton of the D2 feed. Payload-driven sections carry empty configs
// here, so they self-hide rather than render fabricated merchandising numbers;
// what remains offline are the sections with their own data sources.
const _fallbackSections = [
  HomeSection(
    id: 'b',
    title: '',
    sectionType: 'Banner',
    config: {},
    sortOrder: 0,
  ),
  HomeSection(
    id: 'q',
    title: 'Our Services',
    sectionType: 'QuickActions',
    config: {},
    sortOrder: 1,
  ),
  HomeSection(
    id: 'k',
    title: 'Health Packages',
    sectionType: 'FeaturedPackages',
    config: {},
    sortOrder: 3,
  ),
  HomeSection(
    id: 'r',
    title: 'Recommended for You',
    sectionType: 'Recommended',
    config: {},
    sortOrder: 4,
  ),
  HomeSection(
    id: 't',
    title: 'Why book with us',
    sectionType: 'TrustBlock',
    config: {},
    sortOrder: 5,
  ),
  HomeSection(
    id: 'ar',
    title: 'Health reads',
    sectionType: 'Articles',
    config: {},
    sortOrder: 6,
  ),
];

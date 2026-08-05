import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/encrypted_cache.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'models/branding_config.dart';
import 'providers/app_providers.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = await EncryptedCache.open(SecureStorageService());
  runApp(
    ProviderScope(
      overrides: [encryptedCacheProvider.overrideWithValue(cache)],
      child: const Bit2SkyApp(),
    ),
  );
}

class Bit2SkyApp extends ConsumerWidget {
  const Bit2SkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme is derived from DB-driven branding (white-label, Section 5 / Part 9).
    final branding = ref.watch(brandingProvider).maybeWhen(
          data: (b) => b,
          orElse: () => BrandingConfig.fallback,
        );

    return MaterialApp.router(
      title: branding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(branding),
      routerConfig: appRouter,
    );
  }
}

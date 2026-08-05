import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/home_shell.dart';
import 'models/branding_config.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await SecureStorageService().accessToken;
  runApp(ProviderScope(
      child: PartnerApp(start: token == null ? '/login' : '/home')));
}

class PartnerApp extends ConsumerWidget {
  final String start;
  const PartnerApp({super.key, required this.start});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider).maybeWhen(
        data: (b) => b,
        orElse: () => const BrandingConfig(
            appName: 'VitalScan Partner', primaryColor: '#00897B'));

    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
        GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      ],
    );

    return MaterialApp.router(
      title: 'VitalScan Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(branding),
      routerConfig: router,
    );
  }
}

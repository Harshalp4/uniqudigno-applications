import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/booking_detail_screen.dart';
import 'features/home_shell.dart';
import 'features/login_screen.dart';
import 'models/branding_config.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await SecureStorageService().accessToken;
  runApp(ProviderScope(
      child: TechnicianApp(start: token == null ? '/login' : '/today')));
}

class TechnicianApp extends ConsumerWidget {
  final String start;
  const TechnicianApp({super.key, required this.start});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider).maybeWhen(
        data: (b) => b,
        orElse: () => const BrandingConfig(
            appName: 'VitalScan Tech', primaryColor: '#00695C'));

    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/today', builder: (_, _) => const HomeShell()),
        GoRoute(
          path: '/booking/:id',
          builder: (_, s) =>
              BookingDetailScreen(bookingId: s.pathParameters['id']!),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'VitalScan Technician',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(branding),
      routerConfig: router,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../auth/profile_setup_screen.dart';

/// Splash (Part 6/Screen1) — radial teal gradient, logo + app name + tagline.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    // Warm the DB-driven config while the splash animates.
    ref.read(brandingProvider);
    ref.read(featureFlagsProvider);
    ref.read(authProvider.notifier).bootstrap();
    ref.read(deviceCompromisedProvider); // root/jailbreak check at start
    _navTimer = Timer(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      final authed =
          ref.read(authProvider).status == AuthStatus.authenticated;
      if (authed) {
        // Same gate as fresh logins: incomplete profiles land on /auth/setup,
        // so the mandatory first-time form can't be escaped by relaunching.
        if (mounted) await routeAfterLogin(context, ref);
        return;
      }
      final seenOnboarding = await SecureStorageService().onboardingSeen;
      if (mounted) context.go(seenOnboarding ? '/login' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final tagline = branding.maybeWhen(
        data: (b) => b.tagline ?? '', orElse: () => 'Health, decoded.');

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.splashRadial),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s24, vertical: AppSpacing.s20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r24),
                      boxShadow: AppShadows.shadowTeal,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Text(tagline,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

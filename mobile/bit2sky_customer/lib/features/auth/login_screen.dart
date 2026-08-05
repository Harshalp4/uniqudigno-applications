import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_palette_provider.dart';
import 'google_sign_in_helper.dart';
import 'login_slides.dart';
import 'profile_setup_screen.dart';

/// Login — wireframe option K: a swipeable hero carousel of five diagnostic
/// vignettes (DNA helix → report → sample drop → ECG → health score), each
/// with its own looping animation and message, over a fixed email-OTP sheet.
/// Auto-advances every 4s; pauses while typing; static under reduce-motion.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  String? _error;

  /// Drives the CTA sheen sweep.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _email.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    if (!_emailRegex.hasMatch(value)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() => _error = null);
    final ok = await ref.read(authProvider.notifier).sendEmailOtp(value);
    if (ok && mounted) context.push('/otp');
  }

  Future<void> _google() async {
    final err = await signInWithGoogle(ref);
    if (!mounted) return;
    if (err == null) {
      await routeAfterLogin(context, ref); // new user → /auth/setup
    } else if (err != 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final palette = ref.watch(brandPaletteProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
          children: [
            Expanded(
              child: _HeroCarousel(pauseListenable: _emailFocus),
            ),
            // ── Fixed login sheet ──
            Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -18, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 28,
                      offset: Offset(0, -8)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s20,
                  AppSpacing.s20, AppSpacing.s8 + bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand identity: the full Unique Diagnostic Centre logo
                  // (transparent PNG) anchors the sheet.
                  Center(
                    child: Image.asset(
                      'assets/images/logo_full.png',
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text('Login',
                      style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w800, fontSize: 19)),
                  const SizedBox(height: AppSpacing.s12),
                  _EmailField(
                    controller: _email,
                    focusNode: _emailFocus,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  if (_error != null || auth.error != null) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(_error ?? auth.error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.errorRed)),
                  ],
                  const SizedBox(height: AppSpacing.s12),
                  _SheenCta(
                    label: 'Receive OTP',
                    loading: auth.busy,
                    palette: palette,
                    sheen: _sheen,
                    onTap: auth.busy ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SquareAction(
                        semantics: 'Continue with Google',
                        caption: 'Google',
                        onTap: _google,
                        child: Image.asset('assets/images/google_g.png',
                            height: 22,
                            errorBuilder: (_, _, _) => const Text('G',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4)))),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      _SquareAction(
                        semantics: 'Continue as Guest',
                        caption: 'Guest',
                        onTap: () => context.go('/home'),
                        child: Icon(Icons.person_outline_rounded,
                            size: 24, color: palette.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Center(
                    child: Text.rich(
                      const TextSpan(
                        text: 'By signing in, you accept our ',
                        children: [
                          TextSpan(
                              text: 'T&Cs and Privacy Policy.',
                              style: TextStyle(
                                  decoration: TextDecoration.underline)),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }
}

/// Swipeable auto-advancing hero: 5 diagnostic vignettes + animated dots.
/// Pauses while [pauseListenable] (the email field) has focus and under
/// reduce-motion; manual swipes just move on to the next 4s window.
class _HeroCarousel extends StatefulWidget {
  final FocusNode pauseListenable;
  const _HeroCarousel({required this.pauseListenable});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  static const _count = 5;
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    widget.pauseListenable.addListener(_syncTimer);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  void _syncTimer() {
    final animate = !MediaQuery.of(context).disableAnimations &&
        !widget.pauseListenable.hasFocus;
    if (animate && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_controller.hasClients) return;
        _controller.animateToPage(
          (_page + 1) % _count,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    } else if (!animate) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    widget.pauseListenable.removeListener(_syncTimer);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _page = i),
          children: const [
            DnaHelixSlide(),
            ReportSlide(),
            SampleDropSlide(),
            EcgPaperSlide(),
            HealthScoreSlide(),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == _page ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    // Dark DNA slide gets light dots for contrast.
                    color: i == _page
                        ? (_page == 0 ? Colors.white : const Color(0xFF428AC7))
                        : (_page == 0
                            ? const Color(0x66FFFFFF)
                            : const Color(0xFFC6CDD8)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  const _EmailField({required this.controller, this.focusNode, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.emailAddress,
        style: AppTextStyles.body.copyWith(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: 'Enter your e-mail ID',
          hintStyle: AppTextStyles.body
              .copyWith(fontSize: 14.5, color: AppColors.textDisabled),
          icon: const Icon(Icons.mail_outline,
              size: 20, color: AppColors.textDisabled),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

/// Gradient CTA with the periodic sheen sweep (same language as BOOK NOW).
class _SheenCta extends StatelessWidget {
  final String label;
  final bool loading;
  final BrandPalette palette;
  final Animation<double> sheen;
  final VoidCallback? onTap;

  const _SheenCta({
    required this.label,
    required this.loading,
    required this.palette,
    required this.sheen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            gradient: LinearGradient(
                colors: [palette.primary, palette.primaryDark]),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: sheen,
                builder: (context, _) {
                  final t = Curves.easeInOut
                      .transform((sheen.value / 0.4).clamp(0.0, 1.0));
                  if (t <= 0.0 || t >= 1.0) return const SizedBox.shrink();
                  return FractionalTranslation(
                    translation: Offset(-1.2 + 2.4 * t, 0),
                    child: Transform.rotate(
                      angle: 0.35,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : Text(label,
                        style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square social/guest action with a small caption.
class _SquareAction extends StatelessWidget {
  final Widget child;
  final String caption;
  final String semantics;
  final VoidCallback onTap;

  const _SquareAction({
    required this.child,
    required this.caption,
    required this.semantics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(color: AppColors.borderDefault),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                      offset: Offset(0, 3)),
                ],
              ),
              child: child,
            ),
            const SizedBox(height: 4),
            Text(caption,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

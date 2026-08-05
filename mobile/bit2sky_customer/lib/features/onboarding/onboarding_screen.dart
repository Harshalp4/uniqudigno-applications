import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/misc_models.dart';
import '../../providers/misc_provider.dart';

/// Onboarding carousel (Part 6/Screen2) — full-bleed image slides, DB-driven,
/// shown on first launch. Skip top-right, circular next bottom-right.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SecureStorageService().setOnboardingSeen();
    if (mounted) context.go('/login');
  }

  void _next(int count) {
    if (_index == count - 1) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(onboardingSlidesProvider).maybeWhen(
        data: (s) => s, orElse: () => const <OnboardingSlide>[]);
    if (slides.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.teal800,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: slides.length,
            itemBuilder: (_, i) => _Slide(slide: slides[i]),
          ),

          // Skip — top-right, over the image.
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),

          // Dots (left) + circular next (right) — bottom bar over the image.
          Positioned(
            left: AppSpacing.s24,
            right: AppSpacing.s24,
            bottom: AppSpacing.s32,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppRadius.r100),
                        ),
                      ),
                    ),
                  ),
                  _NextButton(onTap: () => _next(slides.length)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One full-bleed slide: image with a bottom gradient + title/subtitle.
class _Slide extends StatelessWidget {
  final OnboardingSlide slide;
  const _Slide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (slide.imageUrl.isNotEmpty)
          Image.network(
            slide.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const ColoredBox(color: AppColors.teal800),
            errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.packageHeader)),
          )
        else
          const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.packageHeader)),

        // Dark → teal gradient so white text stays legible over any photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.35),
                AppColors.teal800.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.s24, 0, AppSpacing.s24, 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slide.title,
                  style: AppTextStyles.display.copyWith(color: Colors.white)),
              if (slide.subtitle != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(slide.subtitle!,
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.arrow_forward, color: AppColors.teal700),
        ),
      ),
    );
  }
}

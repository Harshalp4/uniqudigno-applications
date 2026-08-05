import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/misc_models.dart';
import 'app_providers.dart';

final onboardingSlidesProvider = FutureProvider<List<OnboardingSlide>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/onboarding/slides');
    final list =
        data.map((e) => OnboardingSlide.fromJson(e as Map<String, dynamic>)).toList();
    return list.isEmpty ? _fallbackSlides : list;
  } catch (_) {
    return _fallbackSlides;
  }
});

final cashbackOffersProvider = FutureProvider<List<CashbackOffer>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/cashback/active-offers');
    return data.map((e) => CashbackOffer.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

const _fallbackSlides = [
  OnboardingSlide(
      title: 'Book lab tests from your doorstep',
      subtitle: 'Certified phlebotomists collect samples at home, at your convenience.',
      imageUrl:
          'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=900&q=80&auto=format&fit=crop'),
  OnboardingSlide(
      title: 'Understand your health with AI insights',
      subtitle: 'Get plain-language explanations of every report parameter from Wellio.',
      imageUrl:
          'https://images.unsplash.com/photo-1576671081837-49000212a370?w=900&q=80&auto=format&fit=crop'),
  OnboardingSlide(
      title: "Manage your entire family's health",
      subtitle: 'One vault for reports, prescriptions and trends — for up to 6 members.',
      imageUrl:
          'https://images.unsplash.com/photo-1511174511562-5f7f18b874f8?w=900&q=80&auto=format&fit=crop'),
];

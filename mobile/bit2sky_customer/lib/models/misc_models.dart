/// Onboarding + cashback models (content / commerce APIs).
library;

class OnboardingSlide {
  final String title;
  final String? subtitle;
  final String imageUrl;

  const OnboardingSlide({required this.title, this.subtitle, required this.imageUrl});

  factory OnboardingSlide.fromJson(Map<String, dynamic> j) => OnboardingSlide(
        title: (j['title'] ?? '').toString(),
        subtitle: j['subtitle']?.toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
      );
}

class CashbackOffer {
  final String title;
  final String? description;
  final String rewardType; // Percentage | Flat
  final double rewardValue;
  final double? maxCashback;
  final String? validUntil;

  const CashbackOffer({
    required this.title,
    this.description,
    required this.rewardType,
    required this.rewardValue,
    this.maxCashback,
    this.validUntil,
  });

  String get rewardLabel => rewardType == 'Percentage'
      ? '${rewardValue.toStringAsFixed(0)}% cashback'
      : '₹${rewardValue.toStringAsFixed(0)} cashback';

  factory CashbackOffer.fromJson(Map<String, dynamic> j) => CashbackOffer(
        title: (j['title'] ?? '').toString(),
        description: j['description']?.toString(),
        rewardType: (j['rewardType'] ?? 'Percentage').toString(),
        rewardValue: ((j['rewardValue'] ?? 0) as num).toDouble(),
        maxCashback: (j['maxCashback'] as num?)?.toDouble(),
        validUntil: j['validUntil']?.toString(),
      );
}

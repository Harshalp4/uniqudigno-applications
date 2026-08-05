import 'package:flutter/widgets.dart';

/// Motion tokens for the home redesign. Subtle and fast — if a transition is
/// noticeable as an animation rather than as responsiveness, it is too slow.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve easeOut = Curves.easeOutCubic;

  /// Press/badge feedback only — never for layout transitions.
  static const Curve emphasized = Curves.easeOutBack;

  /// Per-section entrance stagger step.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Accessibility: collapse any duration to zero when the platform asks for
  /// reduced motion. Wrap EVERY animated duration in this.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
}

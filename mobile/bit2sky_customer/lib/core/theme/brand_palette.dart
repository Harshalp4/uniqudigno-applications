import 'package:flutter/material.dart';

import 'app_colors.dart';

/// D1 — Brand tonal ramp derived at runtime from the DB-driven branding
/// primary color (`/config/branding` → primary_color), so a white-label
/// rebrand recolors the whole app without a rebuild.
///
/// Shade naming mirrors the Material ramp already used by the static tokens:
///   tint (50)       chip backgrounds, light badges, input focus
///   tintStrong (100) skeleton loaders, divider accents
///   primary (700)   CTAs, links, active states, icons
///   primaryDark (800) pressed states, gradient ends, headers on dark
///
/// The static [AppColors] teal constants remain the compile-time fallback;
/// new (D-track) components take their colors from this palette instead.
class BrandPalette {
  final Color primary;
  final Color primaryDark;
  final Color tint;
  final Color tintStrong;

  /// Sparing secondary accent (branding secondary_color — the logo's cyan).
  /// Falls back to [primaryDark]. NEVER a money surface (amber) and never a
  /// health-status color — highlights and illustrative icons only.
  final Color accent;

  /// Bottom-nav selection accent (branding nav_accent_color). Falls back to
  /// [primary], so an unset key keeps the nav on-brand.
  final Color navAccent;

  const BrandPalette({
    required this.primary,
    required this.primaryDark,
    required this.tint,
    required this.tintStrong,
    Color? accent,
    Color? navAccent,
  })  : accent = accent ?? primaryDark,
        navAccent = navAccent ?? primary;

  /// Compile-time fallback — identical to the current teal tokens.
  static const fallback = BrandPalette(
    primary: AppColors.teal700,
    primaryDark: AppColors.teal800,
    tint: AppColors.teal50,
    tintStrong: AppColors.teal100,
  );

  /// Derives the ramp from a single primary color via HSL: the dark shade
  /// drops lightness, the tints raise lightness and soften saturation so
  /// they read as surfaces rather than color.
  factory BrandPalette.fromPrimary(Color primary,
      {Color? accent, Color? navAccent}) {
    final hsl = HSLColor.fromColor(primary);
    Color shade(double lightness, double saturation) => hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation(saturation.clamp(0.0, 1.0))
        .toColor();
    return BrandPalette(
      primary: primary,
      primaryDark: shade(hsl.lightness * 0.72, hsl.saturation),
      tint: shade(0.94, hsl.saturation * 0.55),
      tintStrong: shade(0.85, hsl.saturation * 0.50),
      accent: accent,
      navAccent: navAccent,
    );
  }

  /// Parses `#RRGGBB` branding hexes straight into a ramp.
  factory BrandPalette.fromHex(String? hex,
          {String? accentHex, String? navAccentHex}) =>
      hex == null || hex.isEmpty
          ? fallback
          : BrandPalette.fromPrimary(
              AppColors.fromHex(hex),
              accent: accentHex == null || accentHex.isEmpty
                  ? null
                  : AppColors.fromHex(accentHex),
              navAccent: navAccentHex == null || navAccentHex.isEmpty
                  ? null
                  : AppColors.fromHex(navAccentHex),
            );

  /// Hero/package-header gradient — the ONLY sanctioned primary gradient
  /// (premium ≠ busy: gradients live on hero and offer surfaces only).
  LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryDark],
      );

  /// Soft glow for the primary CTA, tinted by the brand color.
  List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

import 'package:flutter/material.dart';

/// Bit2Sky / VitalScan color system (Visual Design System — Part 2).
/// Status colors are used precisely (health status only), never decoratively.
class AppColors {
  AppColors._();

  // ── Primary palette ──
  static const teal700 = Color(0xFF00897B); // brand primary — CTAs, active, icons
  static const teal800 = Color(0xFF00695C); // pressed, headers on dark
  static const teal50 = Color(0xFFE0F2F1); // chip bg, light badges, input focus
  static const teal100 = Color(0xFFB2DFDB); // skeletons, divider accents

  // ── Status colors ──
  static const successGreen = Color(0xFF43A047);
  static const successLight = Color(0xFFE8F5E9);
  static const warningOrange = Color(0xFFFB8C00);
  static const warningLight = Color(0xFFFFF3E0);
  static const errorRed = Color(0xFFE53935);
  static const errorLight = Color(0xFFFFEBEE);

  // ── Accent ──
  static const blueAccent = Color(0xFF2979FF);
  static const blueLight = Color(0xFFE3F2FD);

  // ── Neutral palette ──
  static const background = Color(0xFFF8FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF4F6F8);
  static const borderDefault = Color(0xFFE5E7EB);
  static const borderStrong = Color(0xFFD1D5DB);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFFFFFFF);

  /// Splash radial gradient (Part 2 — only on splash/hero).
  static const splashRadial = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 0.9,
    colors: [teal700, teal50, background],
    stops: [0.0, 0.7, 1.0],
  );

  /// Package card header gradient (Part 5 / C7).
  static const packageHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal700, teal800],
  );

  /// Parse a `#RRGGBB` branding hex into a [Color] (falls back to teal700).
  static Color fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return teal700;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value == null ? teal700 : Color(value);
  }
}

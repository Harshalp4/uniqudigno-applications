import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type scale (Visual Design System — Part 3). Inter via google_fonts.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    required double height,
    double spacing = 0,
    Color color = AppColors.textPrimary,
    TextDecoration? decoration,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: color,
    decoration: decoration,
  );

  static TextStyle get displayLarge =>
      _inter(size: 28, weight: FontWeight.w800, height: 1.18);
  static TextStyle get display =>
      _inter(size: 24, weight: FontWeight.w700, height: 1.22);
  static TextStyle get h1 =>
      _inter(size: 20, weight: FontWeight.w700, height: 1.28);
  static TextStyle get h2 =>
      _inter(size: 18, weight: FontWeight.w700, height: 1.3);
  static TextStyle get h3 =>
      _inter(size: 16, weight: FontWeight.w600, height: 1.35);
  static TextStyle get h4 =>
      _inter(size: 14, weight: FontWeight.w600, height: 1.35);
  static TextStyle get bodyLarge =>
      _inter(size: 15, weight: FontWeight.w400, height: 1.5);
  static TextStyle get body =>
      _inter(size: 13, weight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall =>
      _inter(size: 12, weight: FontWeight.w400, height: 1.45);
  static TextStyle get caption =>
      _inter(size: 11, weight: FontWeight.w400, height: 1.4);
  static TextStyle get label =>
      _inter(size: 11, weight: FontWeight.w600, height: 1.25);
  static TextStyle get buttonLarge =>
      _inter(size: 14, weight: FontWeight.w600, height: 1.0);
  static TextStyle get button =>
      _inter(size: 13, weight: FontWeight.w600, height: 1.0);
  static TextStyle get priceLarge =>
      _inter(size: 18, weight: FontWeight.w700, height: 1.0);
  static TextStyle get priceStrikethrough => _inter(
    size: 12,
    weight: FontWeight.w400,
    height: 1.0,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
  );

  // ── Home density redesign tokens ──
  // A deliberately tighter scale than the legacy getters above. Line heights
  // are exact px specs expressed as ratios. Card contexts must also set
  // maxLines + TextOverflow.ellipsis — 3-line titles are why cards are tall.
  /// "Hi, Guest" — 20/26 w700.
  static TextStyle get greeting =>
      _inter(size: 20, weight: FontWeight.w700, height: 26 / 20);

  /// Section titles — 17/22 w700.
  static TextStyle get sectionTitle =>
      _inter(size: 17, weight: FontWeight.w700, height: 22 / 17);

  /// Card titles — 15/20 w600.
  static TextStyle get cardTitle =>
      _inter(size: 15, weight: FontWeight.w600, height: 20 / 15);

  /// Body in dense contexts — 13/18 w400 (legacy `body` keeps 1.5 height).
  static TextStyle get bodyTight =>
      _inter(size: 13, weight: FontWeight.w400, height: 18 / 13);

  /// Meta/caption in dense contexts — 11/15 w500 (legacy `caption` is w400).
  static TextStyle get captionMed =>
      _inter(size: 11, weight: FontWeight.w500, height: 15 / 11);

  /// Price — 17/22 w700.
  static TextStyle get price =>
      _inter(size: 17, weight: FontWeight.w700, height: 22 / 17);

  /// Struck MRP — 12/16 w400, 55% strength, line-through.
  static TextStyle get priceStrike => _inter(
    size: 12,
    weight: FontWeight.w400,
    height: 16 / 12,
    color: const Color(0x8C6B7280), // textSecondary @ 55%
    decoration: TextDecoration.lineThrough,
  );

  /// CTA labels — 14/18 w600.
  static TextStyle get cta =>
      _inter(size: 14, weight: FontWeight.w600, height: 18 / 14);

  /// Filter chips — 12/16 w500 (tightened to reference proportions).
  static TextStyle get chip =>
      _inter(size: 12, weight: FontWeight.w500, height: 16 / 12);

  /// Compact package-card scale (reference-parity shrink).
  static TextStyle get cardTitleCompact =>
      _inter(size: 13.5, weight: FontWeight.w600, height: 18 / 13.5);
  static TextStyle get priceCompact =>
      _inter(size: 15, weight: FontWeight.w700, height: 20 / 15);
  static TextStyle get ctaCompact =>
      _inter(size: 12.5, weight: FontWeight.w600, height: 16 / 12.5);
}

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
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color,
        decoration: decoration,
      );

  static TextStyle get displayLarge =>
      _inter(size: 32, weight: FontWeight.w800, height: 1.2, spacing: -0.5);
  static TextStyle get display =>
      _inter(size: 28, weight: FontWeight.w700, height: 1.25, spacing: -0.3);
  static TextStyle get h1 =>
      _inter(size: 24, weight: FontWeight.w700, height: 1.3, spacing: -0.2);
  static TextStyle get h2 =>
      _inter(size: 20, weight: FontWeight.w700, height: 1.35, spacing: -0.1);
  static TextStyle get h3 =>
      _inter(size: 18, weight: FontWeight.w600, height: 1.4);
  static TextStyle get h4 =>
      _inter(size: 16, weight: FontWeight.w600, height: 1.4);
  static TextStyle get bodyLarge =>
      _inter(size: 16, weight: FontWeight.w400, height: 1.6);
  static TextStyle get body =>
      _inter(size: 14, weight: FontWeight.w400, height: 1.6);
  static TextStyle get bodySmall =>
      _inter(size: 13, weight: FontWeight.w400, height: 1.5);
  static TextStyle get caption => _inter(
      size: 12, weight: FontWeight.w400, height: 1.5, spacing: 0.2);
  static TextStyle get label => _inter(
      size: 12, weight: FontWeight.w600, height: 1.3, spacing: 0.4);
  static TextStyle get buttonLarge => _inter(
      size: 16, weight: FontWeight.w600, height: 1.0, spacing: 0.1);
  static TextStyle get button => _inter(
      size: 14, weight: FontWeight.w600, height: 1.0, spacing: 0.1);
  static TextStyle get priceLarge => _inter(
      size: 22, weight: FontWeight.w700, height: 1.0, spacing: -0.2);
  static TextStyle get priceStrikethrough => _inter(
      size: 14,
      weight: FontWeight.w400,
      height: 1.0,
      color: AppColors.textSecondary,
      decoration: TextDecoration.lineThrough);
}

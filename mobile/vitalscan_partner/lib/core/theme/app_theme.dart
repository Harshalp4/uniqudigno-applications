import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/branding_config.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Complete ThemeData implementing the design system (Part 9).
/// Reads the primary color from BrandingConfig (not hardcoded).
class AppTheme {
  AppTheme._();

  static ThemeData build(BrandingConfig branding) {
    final primary = AppColors.fromHex(branding.primaryColor);

    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        surface: AppColors.surface,
        error: AppColors.errorRed,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h3.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          textStyle: AppTextStyles.buttonLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: AppTextStyles.buttonLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
        labelStyle:
            AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textDisabled,
        selectedLabelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: primary,
        labelStyle: AppTextStyles.label,
        side: const BorderSide(color: AppColors.borderDefault),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 1,
        space: 0,
      ),
    );
  }
}

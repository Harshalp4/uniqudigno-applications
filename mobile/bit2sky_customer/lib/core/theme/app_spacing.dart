import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing, radius and shadow scales (Visual Design System — Part 4). 4px grid.
class AppSpacing {
  AppSpacing._();

  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  static const double bottomNavHeight = 64;
  static const double headerHeight = 56;

  // ── Semantic aliases (home density redesign) ──
  // Use these — not raw steps — inside the home feature, so the rhythm rules
  // are enforced by name: screen gutter 16, section gap 24, title→content 12,
  // card padding 12, gap between cards in a rail 12.
  static const double screenHPad = s16;
  static const double sectionGap = s24;
  static const double titleToContent = s12;
  static const double cardPad = s12;
  static const double cardGap = s12;
}

class AppRadius {
  AppRadius._();

  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16; // standard cards
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r100 = 100; // pills, FABs
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadow3 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shadow4 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadowTeal = [
    BoxShadow(color: Color(0x59428AC7), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> primaryButton = [
    BoxShadow(color: Color(0x4D428AC7), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // ── Card treatment (home density redesign) ──
  // One soft shadow + a 1px hairline border reads lighter than Material
  // elevation's diffuse grey blur. Kill `elevation:` on cards; use these.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0B1B33), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const Color hairline = Color(0x0F000000);

  // ignore: unused_field — kept to anchor the palette dependency.
  static const Color _anchor = AppColors.teal700;
}

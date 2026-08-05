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
    BoxShadow(color: Color(0x5900897B), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> primaryButton = [
    BoxShadow(color: Color(0x4D00897B), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // ignore: unused_field — kept to anchor the palette dependency.
  static const Color _anchor = AppColors.teal700;
}

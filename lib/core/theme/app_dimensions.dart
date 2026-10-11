import 'package:flutter/material.dart';

/// Centralized Spacing, Radius, Elevation, and Animation Tokens
class AppDimensions {
  // Spacing Tokens
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Radius Tokens
  static const double radiusXS = 6.0;
  static const double radiusSM = 10.0;
  static const double radiusMD = 14.0;
  static const double radiusLG = 18.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // BorderRadius objects
  static const BorderRadius roundedSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius roundedMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius roundedLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius roundedXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Elevation / Soft Shadows
  static List<BoxShadow> softShadow({Color color = const Color(0x0A000000)}) => [
        BoxShadow(
          color: color,
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> cardShadow({bool isDark = false}) => [
        BoxShadow(
          color: isDark ? const Color(0x33000000) : const Color(0x0F1C1C1E),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> orangeGlow = [
    BoxShadow(
      color: const Color(0xFFFC8019).withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 180);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSplash = Duration(milliseconds: 2000);

  // Animation Curves
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.fastEaseInToSlowEaseOut;
}

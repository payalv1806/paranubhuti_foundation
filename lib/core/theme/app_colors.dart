import 'package:flutter/material.dart';

/// Color tokens translated directly from DESIGN.md ("Kindred Celebration").
/// Do not introduce new colors here — if a screen needs a color not listed,
/// go back to Stitch, add it to the design system, and re-export DESIGN.md.
class AppColors {
  AppColors._();

  static const surface = Color(0xFFFEFCCF);
  static const surfaceDim = Color(0xFFDEDCB1);
  static const surfaceBright = Color(0xFFFEFCCF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF8F6C9);
  static const surfaceContainer = Color(0xFFF2F0C4);
  static const surfaceContainerHigh = Color(0xFFECEABE);
  static const surfaceContainerHighest = Color(0xFFE6E5B9);
  static const onSurface = Color(0xFF1D1D03);
  static const onSurfaceVariant = Color(0xFF57423B);
  static const inverseSurface = Color(0xFF323214);
  static const inverseOnSurface = Color(0xFFF5F3C7);
  static const outline = Color(0xFF8B7169);
  static const outlineVariant = Color(0xFFDEC0B6);
  static const surfaceTint = Color(0xFFA43C12);

  // Primary — Coral: high-energy actions, brand moments, "Donate" buttons
  static const primary = Color(0xFFA43C12);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFF7F50);
  static const onPrimaryContainer = Color(0xFF6C2000);
  static const inversePrimary = Color(0xFFFFB59C);

  // Secondary — Warm Yellow: "magical" moments (goal hit, gift received)
  static const secondary = Color(0xFF705D00);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFCD400);
  static const onSecondaryContainer = Color(0xFF6E5C00);

  // Tertiary — Turquoise: represents "the Cause", used sparingly
  static const tertiary = Color(0xFF006A62);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF00B8AA);
  static const onTertiaryContainer = Color(0xFF00423C);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const primaryFixed = Color(0xFFFFDBCF);
  static const primaryFixedDim = Color(0xFFFFB59C);
  static const onPrimaryFixed = Color(0xFF380C00);
  static const onPrimaryFixedVariant = Color(0xFF822800);

  static const secondaryFixed = Color(0xFFFFE16D);
  static const secondaryFixedDim = Color(0xFFE9C400);
  static const onSecondaryFixed = Color(0xFF221B00);
  static const onSecondaryFixedVariant = Color(0xFF544600);

  static const tertiaryFixed = Color(0xFF61F9E9);
  static const tertiaryFixedDim = Color(0xFF3ADCCC);
  static const onTertiaryFixed = Color(0xFF00201D);
  static const onTertiaryFixedVariant = Color(0xFF005049);

  static const background = Color(0xFFFEFCCF);
  static const onBackground = Color(0xFF1D1D03);
  static const surfaceVariant = Color(0xFFE6E5B9);

  /// Soft ambient shadow tint used on Level-1 cards (10% opacity Coral),
  /// per the "Elevation & Depth" section of DESIGN.md.
  static Color cardShadow = primary.withValues(alpha: 0.10);
}

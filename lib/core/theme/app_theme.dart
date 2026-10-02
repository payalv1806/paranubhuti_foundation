import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Spacing scale from DESIGN.md — use these instead of hardcoded numbers
/// anywhere you write padding/margin/gap values.
class AppSpacing {
  AppSpacing._();
  static const unit = 8.0;
  static const marginMobile = 24.0;
  static const marginDesktop = 64.0;
  static const gutter = 16.0;
  static const sectionGap = 48.0;
}

/// Corner radius scale from DESIGN.md.
class AppRadius {
  AppRadius._();
  static const sm = 4.0; // 0.25rem
  static const md = 8.0; // 0.5rem (default) — inputs, standard buttons
  static const lg = 12.0; // 0.75rem
  static const xl = 16.0; // 1rem
  static const xxl = 24.0; // 1.5rem — cards, "invitation" containers
  static const full = 9999.0; // pill shapes — Donate buttons, progress bars

  // Common semantic aliases
  static const card = xxl;
  static const input = md;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
      ),

      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLg,
        headlineMedium: AppTextStyles.headlineMd,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        labelSmall: AppTextStyles.labelCaps,
        labelLarge: AppTextStyles.buttonText,
      ),

      // Primary buttons: pill-shaped, filled Coral, white text (per DESIGN.md)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.buttonText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionGap,
            vertical: AppSpacing.unit * 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          elevation: 4,
          shadowColor: AppColors.cardShadow,
        ),
      ),

      // Secondary buttons: thick 2px Coral outline, Cream fill
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          textStyle: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionGap,
            vertical: AppSpacing.unit * 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),

      // Cards: white background, 24px radius, soft ambient shadow, 24px padding
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 8,
        shadowColor: AppColors.cardShadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),

      // Inputs: white bg, soft 1px cream border, Coral border on focus,
      // label-caps style label placed above the field
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        labelStyle: AppTextStyles.labelCaps,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.unit * 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // Progress bars: thick pill shape, Coral track (used for fundraiser goals)
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainerHigh,
        linearMinHeight: 12,
      ),
    );
  }
}

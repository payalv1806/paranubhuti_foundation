import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type scale translated directly from DESIGN.md.
/// Fonts required (add via google_fonts package or as local assets):
///   - Plus Jakarta Sans (headlines)
///   - Be Vietnam Pro (body text)
///   - Quicksand (labels & buttons)
///
/// Per DESIGN.md: never use pure black (#000000) for text — always use
/// AppColors.onSurface (warm charcoal) or a darkened Coral for headlines.
class AppTextStyles {
  AppTextStyles._();

  static const _jakarta = 'PlusJakartaSans';
  static const _vietnamPro = 'BeVietnamPro';
  static const _quicksand = 'Quicksand';

  /// Desktop hero / large celebratory headline
  static const displayLg = TextStyle(
    fontFamily: _jakarta,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
    letterSpacing: -0.02 * 40,
    color: AppColors.onSurface,
  );

  /// Mobile hero / large celebratory headline
  static const displayLgMobile = TextStyle(
    fontFamily: _jakarta,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 38 / 32,
    letterSpacing: -0.02 * 32,
    color: AppColors.onSurface,
  );

  /// Section headers (e.g. "Choose a Cause", "Your birthday")
  static const headlineMd = TextStyle(
    fontFamily: _jakarta,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  /// Narrative body text — fundraiser stories, cause descriptions
  static const bodyLg = TextStyle(
    fontFamily: _vietnamPro,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurfaceVariant,
  );

  /// Default body text
  static const bodyMd = TextStyle(
    fontFamily: _vietnamPro,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurfaceVariant,
  );

  /// Functional labels above input fields — always uppercase per DESIGN.md
  static const labelCaps = TextStyle(
    fontFamily: _quicksand,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
    color: AppColors.onSurfaceVariant,
  );

  /// Button text
  static const buttonText = TextStyle(
    fontFamily: _quicksand,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    color: AppColors.onPrimary,
  );
}

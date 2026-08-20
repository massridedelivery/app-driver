import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';

/// Theme-aware neutral colours for migrating the dark-hardcoded screens to
/// light/dark. Only the neutral surfaces/text flip here; brand colours
/// (orange/green/red/mint…) stay in [AppColors] and read the same in both
/// modes. Resolve via `context.palette`.
///
/// The dark values reuse the app's existing tokens, so dark mode looks
/// identical to before the migration.
class AppPalette {
  /// Page/scaffold background.
  final Color bg;

  /// Raised card / tile surface.
  final Color surface;

  /// Subtle overlay container (chips, faint fills).
  final Color surfaceAlt;

  final Color textPrimary;
  final Color textSecondary;

  /// Subtle text and inactive icons.
  final Color textTertiary;

  final Color border;

  /// Elevated sheet over the map (home bottom sheets). Dark = the app's
  /// blue-grey; light = white.
  final Color sheet;

  /// Secondary sheet fill.
  final Color sheetAlt;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.sheet,
    required this.sheetAlt,
  });

  static const dark = AppPalette(
    bg: AppColors.semanticGrayNeutralFgHigh,
    surface: AppColors.semanticGrayNeutralFgMidOnGray,
    surfaceAlt: AppColors.foundationAlphaWhite100,
    textPrimary: AppColors.semanticGrayNeutralBgWhite,
    textSecondary: AppColors.foundationAlphaWhite400,
    textTertiary: AppColors.semanticGrayNeutralFgLowOnGray,
    border: Color(0x1FFFFFFF),
    sheet: Color(0xFF1E2F38),
    sheetAlt: Color(0xFF2C3E4A),
  );

  static const light = AppPalette(
    bg: Color(0xFFF8FAFC),
    surface: Colors.white,
    surfaceAlt: Color(0x0A000000),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    sheet: Colors.white,
    sheetAlt: Color(0xFFF1F5F9),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension AppPaletteContext on BuildContext {
  /// Theme-aware neutral colours for the current brightness.
  AppPalette get palette => AppPalette.of(this);
}

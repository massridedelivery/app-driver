import 'package:flutter/material.dart';

/// Theme-aware neutral colours (red / white / charcoal brand, "design E").
/// Only the neutral surfaces/text flip here; brand accents live in
/// [BrandColors] (`context.brand`). Resolve via `context.palette`.
///
/// Values match the neutrals of [BrandColors] (bg, surface, fill, line,
/// text1–3), so palette-driven and brand-driven screens read as one surface.
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

  /// Elevated sheet over the map (home bottom sheets). Dark = charcoal card;
  /// light = white.
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
    bg: Color(0xFF121316),
    surface: Color(0xFF1E2026),
    surfaceAlt: Color(0xFF23262D),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFA1A6B0),
    textTertiary: Color(0xFF6B7180),
    border: Color(0xFF2C2F37),
    sheet: Color(0xFF1E2026),
    sheetAlt: Color(0xFF23262D),
  );

  static const light = AppPalette(
    bg: Color(0xFFF7F8FA),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF5F6F8),
    textPrimary: Color(0xFF1B1D22),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    border: Color(0xFFE7E9EE),
    sheet: Colors.white,
    sheetAlt: Color(0xFFF5F6F8),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension AppPaletteContext on BuildContext {
  /// Theme-aware neutral colours for the current brightness.
  AppPalette get palette => AppPalette.of(this);
}

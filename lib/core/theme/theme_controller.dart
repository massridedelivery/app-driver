import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:massdrive/core/theme/app_palette.dart';

/// Whether the app renders in dark mode ("โหมดสีเข้ม").
///
/// The app is currently authored dark-first (colours are hard-coded), so the
/// default is dark. This flag drives [MaterialApp.themeMode]; screens migrated
/// to the theme system will follow it, and the toggle already flips every
/// Material-default surface. Persisted in GetStorage.
class DarkModeController extends Notifier<bool> {
  static const _key = 'dark_mode_enabled';

  GetStorage? _box;

  @override
  bool build() {
    try {
      _box = GetStorage();
    } catch (_) {
      _box = null;
    }
    // Default ON — the app ships dark.
    return _box?.read<bool>(_key) ?? true;
  }

  void setEnabled(bool value) {
    state = value;
    _box?.write(_key, value);
  }
}

final darkModeProvider = NotifierProvider<DarkModeController, bool>(
  DarkModeController.new,
);

/// Brand red (#DB1439) — `BrandColors.red`.
const Color _brandRed = Color(0xFFDB1439);

/// Builds a theme whose Material defaults (TextButton, progress indicators,
/// switches, date pickers, text cursor/selection — all driven by
/// `colorScheme.primary`) come out brand red instead of a seed-derived tone.
ThemeData _buildTheme({
  required Brightness brightness,
  required AppPalette palette,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandRed,
    brightness: brightness,
  ).copyWith(
    primary: _brandRed,
    onPrimary: Colors.white,
    secondary: _brandRed,
    onSecondary: Colors.white,
    tertiary: _brandRed,
    onTertiary: Colors.white,
    surface: palette.surface,
    onSurface: palette.textPrimary,
    onSurfaceVariant: palette.textSecondary,
    // Neutral (not seed-tinted) containers for dialogs, sheets, cards, menus.
    surfaceContainerLowest: palette.surface,
    surfaceContainerLow: palette.surface,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surface,
    surfaceContainerHighest: palette.surfaceAlt,
    outline: palette.border,
    outlineVariant: palette.border,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Ibm',
    // Every scaffold reads as one surface with the CommonAppBar (AppPalette.bg).
    scaffoldBackgroundColor: palette.bg,
    colorScheme: scheme,
  );
}

/// Dark theme — charcoal scaffold (AppPalette.dark.bg), IBM Plex Thai.
final ThemeData appDarkTheme = _buildTheme(
  brightness: Brightness.dark,
  palette: AppPalette.dark,
);

/// Light theme — the base for the migration to a real light mode. Material
/// surfaces (dialogs, default scaffolds, migrated screens) use this; screens
/// that still hard-code dark colours are migrated in follow-up PRs.
final ThemeData appLightTheme = _buildTheme(
  brightness: Brightness.light,
  palette: AppPalette.light,
);

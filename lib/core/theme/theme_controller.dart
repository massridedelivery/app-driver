import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:massdrive/core/constants/app_colors.dart';

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

/// Dark theme — matches the app's current look (black scaffold, IBM Plex Thai).
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Ibm',
  // Match the top bar / surfaces (AppPalette.dark.bg) instead of pure black, so
  // every night-mode scaffold reads as one surface with the CommonAppBar.
  scaffoldBackgroundColor: AppColors.semanticGrayNeutralFgHigh,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.foundationOrange600,
    brightness: Brightness.dark,
  ),
);

/// Light theme — the base for the migration to a real light mode. Material
/// surfaces (dialogs, default scaffolds, migrated screens) use this; screens
/// that still hard-code dark colours are migrated in follow-up PRs.
final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Ibm',
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.foundationOrange600,
    brightness: Brightness.light,
  ),
);

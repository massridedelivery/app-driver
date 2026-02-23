import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_constants.dart';
import 'package:massdrive/core/constants/app_locales.dart';
import 'package:massdrive/features/settings/presentation/state/localization_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationNotifier extends Notifier<LocalizationState> {
  static const _languageCodeKey = Constant.languageCode;
  static const _countryCodeKey = Constant.countryCode;

  @override
  LocalizationState build() {
    final defaultLanguage = AppLocales.supportedLanguages[0];
    _loadCurrentLanguage();

    return LocalizationState(
      locale: Locale(defaultLanguage.languageCode, defaultLanguage.countryCode),
      selectedIndex: 0,
      languages: AppLocales.supportedLanguages,
    );
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);
    if (languageCode == null) {
      setLanguage(AppLocales.defaultLocale);
      _loadCurrentLanguage();
    } else {
      final locale = Locale(languageCode, countryCode);
      int selectedIndex = AppLocales.supportedLanguages.indexWhere(
        (l) => l.languageCode == locale.languageCode,
      );

      if (selectedIndex == -1) selectedIndex = 0;
      state = state.copyWith(
        locale: locale,
        selectedIndex: selectedIndex,
        languages: AppLocales.supportedLanguages,
      );
    }
  }

  Future<void> setLanguage(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _saveLanguage(locale);
  }

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  Future<void> _saveLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
    await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
  }
}

final localizationProvider =
    NotifierProvider<LocalizationNotifier, LocalizationState>(
      LocalizationNotifier.new,
    );

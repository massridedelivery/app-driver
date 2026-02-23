import 'package:flutter/material.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/features/settings/domain/entities/language_entity.dart';

class AppLocales {
  static final List<LanguageEntity> _thaiLanguages = [
    LanguageEntity(languageName: 'Thai', languageCode: 'th'),
    LanguageEntity(
      languageName: 'English',
      languageCode: 'en',
      countryCode: 'TH',
    ),
  ];

  static final List<LanguageEntity> _indonesianLanguages = [
    LanguageEntity(languageName: 'Indonesian', languageCode: 'id'),
    LanguageEntity(
      languageName: 'English',
      languageCode: 'en',
      countryCode: 'ID',
    ),
  ];

  static List<LanguageEntity> get supportedLanguages {
    switch (EnvironmentConfig.countryCode.toLowerCase()) {
      case Regions.indonesia:
        return _indonesianLanguages;
      case Regions.thailand:
      default:
        return _thaiLanguages;
    }
  }

  static Locale get defaultLocale => Locale(
    supportedLanguages.first.languageCode,
    supportedLanguages.first.countryCode,
  );
}

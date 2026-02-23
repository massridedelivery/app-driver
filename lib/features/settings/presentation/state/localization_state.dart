import 'package:massdrive/features/settings/domain/entities/language_entity.dart';
import 'package:flutter/material.dart';

class LocalizationState {
  final Locale locale;
  final int selectedIndex;
  final List<LanguageEntity> languages;

  LocalizationState({
    required this.locale,
    required this.selectedIndex,
    required this.languages,
  });

  LocalizationState copyWith({
    Locale? locale,
    int? selectedIndex,
    List<LanguageEntity>? languages,
  }) {
    return LocalizationState(
      locale: locale ?? this.locale,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      languages: languages ?? this.languages,
    );
  }
}

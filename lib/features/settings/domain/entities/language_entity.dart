class LanguageEntity {
  String languageName;
  String languageCode;
  String? countryCode;

  LanguageEntity({
    required this.languageName,
    required this.languageCode,
    this.countryCode,
  });

  @override
  String toString() {
    return '{languageName: $languageName, countryCode: $countryCode, languageCode: $languageCode}';
  }
}

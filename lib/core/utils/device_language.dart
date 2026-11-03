import 'dart:ui';

/// The phone's language as an `Accept-Language` value ("th-TH", "en-US"), so
/// the backend answers errors in it. Thai when the platform reports none.
String deviceLanguageTag([Locale? locale]) {
  final l = locale ?? PlatformDispatcher.instance.locale;
  return l.languageCode.isEmpty || l.languageCode == 'und'
      ? 'th'
      : l.toLanguageTag();
}

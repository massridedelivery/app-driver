import 'dart:ui';

/// The phone's language as an `Accept-Language` value ("th-TH", "en-US"), so
/// the backend answers errors in it. Thai when the platform reports none.
String deviceLanguageTag([Locale? locale]) {
  final l = locale ?? PlatformDispatcher.instance.locale;
  return l.languageCode.isEmpty || l.languageCode == 'und'
      ? 'th'
      : l.toLanguageTag();
}

/// `X-Lang` for the backend: "th" on a Thai phone, "en" otherwise (it
/// supports only these two).
String deviceLangCode([Locale? locale]) =>
    (locale ?? PlatformDispatcher.instance.locale).languageCode == 'en'
        ? 'en'
        : 'th';

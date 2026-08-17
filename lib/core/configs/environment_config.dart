/// Build-time configuration injected via `--dart-define` /
/// `--dart-define-from-file` (see `config/*.json`).
///
/// Defaults point to the dev environment so a plain `flutter run` works
/// without any extra flags.
class EnvironmentConfig {
  static const String env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: Environments.dev,
  );

  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://driver-api-dev.nutchaphut.dev',
  );

  /// WebSocket base URL. Defaults to [apiUrl] with the scheme swapped
  /// (https -> wss), so a single API_BASE_URL define covers both.
  static String get wsUrl {
    const override = String.fromEnvironment('WS_BASE_URL');
    if (override.isNotEmpty) return override;
    return apiUrl.replaceFirst('http', 'ws');
  }

  static const String hostUrl = String.fromEnvironment('HOST_URL');

  static const String schema = String.fromEnvironment('SCHEMA');

  static const String countryCode = String.fromEnvironment(
    'REGION',
    defaultValue: Regions.thailand,
  );

  static const String omiseApiKey = String.fromEnvironment('OMISE_API_KEY');

  /// Build-time defines with no safe default. Missing any of these silently
  /// yields '' at runtime — the usual cause is forgetting to layer
  /// `config/mass_dev.json` on the build command, which breaks Firebase init
  /// and payments in non-obvious ways. All of these live in `mass_dev.json`.
  static const Map<String, String> _requiredDefines = {
    'OMISE_API_KEY': omiseApiKey,
    'APP_ANDROID_FIREBASE_API_KEY':
        String.fromEnvironment('APP_ANDROID_FIREBASE_API_KEY'),
    'APP_ANDROID_FIREBASE_APP_ID':
        String.fromEnvironment('APP_ANDROID_FIREBASE_APP_ID'),
    'APP_ANDROID_FIREBASE_MSG_SENDER_ID':
        String.fromEnvironment('APP_ANDROID_FIREBASE_MSG_SENDER_ID'),
    'APP_ANDROID_FIREBASE_PROJECT_ID':
        String.fromEnvironment('APP_ANDROID_FIREBASE_PROJECT_ID'),
    'APP_ANDROID_FIREBASE_STORAGE_BUCKET':
        String.fromEnvironment('APP_ANDROID_FIREBASE_STORAGE_BUCKET'),
    'APP_IOS_FIREBASE_API_KEY':
        String.fromEnvironment('APP_IOS_FIREBASE_API_KEY'),
    'APP_IOS_FIREBASE_APP_ID':
        String.fromEnvironment('APP_IOS_FIREBASE_APP_ID'),
    'APP_IOS_FIREBASE_MSG_SENDER_ID':
        String.fromEnvironment('APP_IOS_FIREBASE_MSG_SENDER_ID'),
    'APP_IOS_FIREBASE_PROJECT_ID':
        String.fromEnvironment('APP_IOS_FIREBASE_PROJECT_ID'),
    'APP_IOS_FIREBASE_STORAGE_BUCKET':
        String.fromEnvironment('APP_IOS_FIREBASE_STORAGE_BUCKET'),
    'APP_IOS_FIREBASE_BUNDLE_ID':
        String.fromEnvironment('APP_IOS_FIREBASE_BUNDLE_ID'),
  };

  /// Fail fast at boot if any required define is missing, so a mis-built
  /// binary crashes immediately with a clear message instead of failing
  /// later inside Firebase/payment code.
  static void assertConfigured() {
    final missing = [
      for (final entry in _requiredDefines.entries)
        if (entry.value.isEmpty) entry.key,
    ];
    if (missing.isEmpty) return;
    throw StateError(
      'Missing required build-time config: ${missing.join(', ')}.\n'
      'These are provided by config/mass_dev.json. Build with both a backend '
      'file and mass_dev.json, e.g.:\n'
      '  --dart-define-from-file=config/dev.json '
      '--dart-define-from-file=config/mass_dev.json',
    );
  }
}

class Environments {
  /// name of the environment
  final String name;

  /// default constructor
  const Environments(this.name);

  /// preset of common env name 'dev'
  static const dev = 'dev';

  /// preset of common env name 'preprod'
  static const preprod = 'preprod';

  /// preset of common env name 'prod'
  static const prod = 'prod';

  /// preset of common env name 'test'
  static const uat = 'uat';
}

class Regions {
  final String code;

  const Regions(this.code);

  /// preset of region thailand
  static const thailand = 'th';

  /// preset of region indonesia
  static const indonesia = 'id';
}

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

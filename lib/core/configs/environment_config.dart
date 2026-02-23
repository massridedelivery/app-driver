import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  final String flavorName;
  final String region;

  const EnvironmentConfig({required this.flavorName, required this.region});

  static EnvironmentConfig? _instance;

  static EnvironmentConfig getInstance({
    required String flavorName,
    required String region,
  }) {
    if (_instance == null) {
      _instance = EnvironmentConfig(flavorName: flavorName, region: region);
      return _instance!;
    }
    return _instance!;
  }

  static String get fileName {
    if (_instance!.flavorName == Environments.dev) {
      return '.env.dev.${_instance!.region}';
    } else if (_instance?.flavorName == Environments.uat) {
      return '.env.uat.${_instance!.region}';
    } else if (_instance!.flavorName == Environments.prod) {
      return '.env.prod.${_instance!.region}';
    } else {
      return '';
    }
  }

  static String get env {
    return _instance?.flavorName ?? '';
  }

  // get value from file .env.*
  static String get apiUrl {
    return dotenv.env['API_URL'] ?? 'API_URL not found';
  }

  static String get schema {
    return dotenv.env['SCHEMA'] ?? '';
  }

  static String get countryCode {
    return dotenv.env['REGION'] ?? '';
  }

  static String get hostUrl {
    return dotenv.env['HOST_URL'] ?? '';
  }

  static String get omiseApiKey {
    return const .fromEnvironment('OMISE_API_KEY');
  }
}

class Environments {
  /// name of the environment
  final String name;

  /// default constructor
  const Environments(this.name);

  /// preset of common env name 'dev'
  static const dev = 'dev';

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

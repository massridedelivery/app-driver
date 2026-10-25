import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/configs/environment_config.dart';

/// Run with the prod defines to check what a prod build talks to:
///   flutter test test/prod_config_test.dart \
///     --dart-define-from-file=config/prod.json \
///     --dart-define-from-file=config/mass_prod.json
/// Skipped in a plain `flutter test` (no defines → dev).
void main() {
  final isProd = EnvironmentConfig.env == Environments.prod;

  test('prod build: REST and socket both on the prod backend', () {
    expect(EnvironmentConfig.apiUrl, 'https://driver-api.nueng-hok-paed.com');
    expect(EnvironmentConfig.wsUrl, 'wss://driver-api.nueng-hok-paed.com');
    expect(EnvironmentConfig.apiUrl, isNot(contains('nutchaphut')));
  }, skip: isProd ? false : 'needs --dart-define-from-file=config/prod.json');
}

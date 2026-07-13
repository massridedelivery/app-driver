import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/configs/environment_config.dart';

void main() {
  group('EnvironmentConfig defaults', () {
    // With no --dart-define supplied, the compiled-in defaults apply.
    test('falls back to the dev environment', () {
      expect(EnvironmentConfig.env, Environments.dev);
    });

    test('falls back to the dev API base URL', () {
      expect(EnvironmentConfig.apiUrl, 'https://driver-api-dev.nutchaphut.dev');
    });

    test('derives the WebSocket URL from the API URL (https -> wss)', () {
      expect(EnvironmentConfig.wsUrl, 'wss://driver-api-dev.nutchaphut.dev');
    });

    test('falls back to the Thailand region', () {
      expect(EnvironmentConfig.countryCode, Regions.thailand);
    });
  });
}

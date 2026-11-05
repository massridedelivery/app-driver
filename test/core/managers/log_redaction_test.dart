import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/managers/api/logs/app_dio_logs.dart';

void main() {
  test('tokens never reach the HTTP log, at any depth', () {
    final out = redactSecrets({
      'refresh_token': 'r',
      'data': {
        'access_token': 'a',
        'expires_in': 3600,
        'devices': [
          {'fcm_token': 'f', 'platform': 'ios'},
        ],
      },
      'Authorization': 'Bearer x',
      'phone': '0653333333',
    });
    expect(out, {
      'refresh_token': '*****',
      'data': {
        'access_token': '*****',
        'expires_in': 3600,
        'devices': [
          {'fcm_token': '*****', 'platform': 'ios'},
        ],
      },
      'Authorization': '*****',
      'phone': '0653333333',
    });
  });
}

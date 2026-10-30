import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/services/crash_reporting.dart';

String _jwt(Map<String, dynamic> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.sig';
}

void main() {
  test('reads user_id from an access token', () {
    expect(
      driverIdFromJwt(_jwt({'user_id': '290b1485-f6c8', 'role': 'driver'})),
      '290b1485-f6c8',
    );
  });

  test('a token without user_id, or garbage, gives null', () {
    expect(driverIdFromJwt(_jwt({'role': 'driver'})), isNull);
    expect(driverIdFromJwt('not-a-jwt'), isNull);
    expect(driverIdFromJwt('a.%%%.c'), isNull);
  });

  test('the driver id is hashed, stable and not the raw id', () {
    final h = hashDriverId('290b1485-f6c8');
    expect(h, hashDriverId('290b1485-f6c8'));
    expect(h, hasLength(64));
    expect(h, isNot(contains('290b1485')));
  });
}

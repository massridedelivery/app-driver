import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/auth/domain/otp_errors.dart';

DioException http(int status, Object data, {Map<String, List<String>>? h}) {
  final req = RequestOptions(path: '/auth/otp');
  return DioException(
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(h ?? {}),
    ),
    type: DioExceptionType.badResponse,
  );
}

/// BE dev117 OTP answers.
void main() {
  group('verify errors', () {
    test('wrong code: BE message shown, code still usable', () {
      final e = otpVerifyErrorFrom(
        http(401, {
          'error': 'รหัส OTP ไม่ถูกต้อง',
          'code': 'INVALID_OTP',
          'attempts_left': 3,
        }),
      )!;
      expect(friendlyErrorMessage(e), 'รหัส OTP ไม่ถูกต้อง');
      expect(e.needsNewCode, isFalse);
    });

    test('expired / replaced code → ask for a new one now', () {
      final e = otpVerifyErrorFrom(
        http(410, {
          'error': 'รหัส OTP หมดอายุ กรุณาขอรหัสใหม่',
          'code': 'OTP_EXPIRED',
        }),
      )!;
      expect(friendlyErrorMessage(e), 'รหัส OTP หมดอายุ กรุณาขอรหัสใหม่');
      expect(e.needsNewCode, isTrue);
    });

    test('5 wrong tries → ask for a new one now', () {
      final e = otpVerifyErrorFrom(
        http(429, {
          'error': 'ใส่รหัสผิดเกินจำนวน กรุณาขอรหัสใหม่',
          'code': 'TOO_MANY_ATTEMPTS',
        }),
      )!;
      expect(e.needsNewCode, isTrue);
    });

    test('no error text → no typed error', () {
      expect(otpVerifyErrorFrom(http(500, 'boom')), isNull);
    });
  });

  group('send rate limit', () {
    test('retry_after from the body', () {
      final e = otpRateLimitFrom(
        http(429, {
          'error': 'ขอรหัสเกินจำนวน กรุณาลองใหม่ใน 12 นาที',
          'code': 'OTP_RATE_LIMITED',
          'retry_after': 720,
        }),
      )!;
      expect(e.retryAfter, const Duration(minutes: 12));
      expect(friendlyErrorMessage(e), 'ขอรหัสเกินจำนวน กรุณาลองใหม่ใน 12 นาที');
    });

    test('falls back to the Retry-After header', () {
      final e = otpRateLimitFrom(
        http(
          429,
          {'error': 'ขอรหัสเกินจำนวน', 'code': 'OTP_RATE_LIMITED'},
          h: {
            'retry-after': ['90'],
          },
        ),
      )!;
      expect(e.retryAfter, const Duration(seconds: 90));
    });

    test('not rate limited → null', () {
      expect(otpRateLimitFrom(http(400, {'error': 'bad phone'})), isNull);
    });
  });
}

import 'package:dio/dio.dart';

/// OTP verify refused (BE dev117): 401 `INVALID_OTP`, 410 `OTP_EXPIRED`,
/// 429 `TOO_MANY_ATTEMPTS`. [message] is the backend's Thai `error`.
class OtpVerifyException implements Exception {
  const OtpVerifyException(this.message, {this.code = ''});

  final String message;
  final String code;

  /// This code can't be used any more: the driver needs a new one now.
  bool get needsNewCode => code == 'OTP_EXPIRED' || code == 'TOO_MANY_ATTEMPTS';

  @override
  String toString() => 'Exception: $message';
}

/// OTP send refused: 429 `OTP_RATE_LIMITED`, try again after [retryAfter].
class OtpRateLimitedException implements Exception {
  const OtpRateLimitedException(this.message, {this.retryAfter});

  final String message;
  final Duration? retryAfter;

  @override
  String toString() => 'Exception: $message';
}

/// The typed error for a failed `/auth/otp/verify`, or null when the body
/// carries no `error` text.
OtpVerifyException? otpVerifyErrorFrom(DioException e) {
  final data = e.response?.data;
  if (data is! Map) return null;
  final message = data['error']?.toString() ?? '';
  if (message.isEmpty) return null;
  return OtpVerifyException(message, code: data['code']?.toString() ?? '');
}

/// The typed error for a rate-limited `/auth/otp/send`, or null otherwise.
/// `retry_after` (seconds) comes from the body, else the Retry-After header.
OtpRateLimitedException? otpRateLimitFrom(DioException e) {
  final res = e.response;
  final data = res?.data;
  final code = data is Map ? data['code']?.toString() : null;
  if (res?.statusCode != 429 && code != 'OTP_RATE_LIMITED') return null;
  final message =
      (data is Map ? data['error']?.toString() : null) ??
      'ขอรหัสเกินจำนวน กรุณาลองใหม่ภายหลัง';
  final raw = data is Map ? data['retry_after'] : null;
  final seconds = raw is num
      ? raw.toInt()
      : int.tryParse(res?.headers.value('retry-after') ?? '');
  return OtpRateLimitedException(
    message,
    retryAfter: seconds != null && seconds > 0
        ? Duration(seconds: seconds)
        : null,
  );
}

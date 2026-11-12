import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/utils/thai_phone.dart';

/// A refused phone change, with the text the sheet shows as it is.
class PhoneChangeException implements Exception {
  const PhoneChangeException(this.message, {this.code = '', this.retryAfter});

  static const fallback = 'เปลี่ยนเบอร์โทรไม่สำเร็จ กรุณาลองใหม่';
  static const phoneInUse = 'เบอร์นี้ใช้กับบัญชีอื่นอยู่แล้ว';
  static const codeMismatch = 'รหัสนี้ไม่ได้ส่งให้เบอร์นี้ กรุณาขอรหัสใหม่';

  final String message;

  /// The backend's `code` (`INVALID_PHONE`, `PHONE_IN_USE`, `INVALID_OTP`…).
  final String code;

  /// For `OTP_RATE_LIMITED`: when a new code can be asked for.
  final Duration? retryAfter;

  /// About the number, not the code: shown under the phone field.
  bool get aboutPhone => code == 'INVALID_PHONE' || code == 'PHONE_IN_USE';

  /// This code can't be used any more: ask for a new one now.
  bool get needsNewCode =>
      code == 'OTP_EXPIRED' ||
      code == 'TOO_MANY_ATTEMPTS' ||
      code == 'OTP_MISMATCH';

  @override
  String toString() => 'PhoneChangeException($code): $message';
}

/// The driver's own number, changed with an SMS code (BE v1.6.26):
/// POST /auth/phone/send, then POST /auth/phone/verify. On success the new
/// number is on the account, verified, and signs the driver in from then on.
class PhoneLinkApi {
  PhoneLinkApi(this._dio);

  final Dio _dio;

  /// Texts a code to [phone]; returns the `ref_id` the verify needs.
  Future<String> sendCode(String phone) async {
    try {
      final res = await _dio.post<dynamic>(
        Endpoints.phoneLinkSend,
        data: {'phone': toThaiE164(phone)},
      );
      final data = res.data;
      return data is Map ? data['ref_id']?.toString() ?? '' : '';
    } on DioException catch (e) {
      throw phoneChangeErrorOf(e);
    }
  }

  /// Checks [otp]; returns the number now on the account (E.164).
  Future<String> verify({
    required String phone,
    required String otp,
    required String refId,
  }) async {
    final e164 = toThaiE164(phone);
    try {
      final res = await _dio.post<dynamic>(
        Endpoints.phoneLinkVerify,
        data: {'phone': e164, 'otp': otp, 'ref_id': refId},
      );
      final data = res.data;
      final saved = data is Map ? data['phone']?.toString() ?? '' : '';
      return saved.isEmpty ? e164 : saved;
    } on DioException catch (e) {
      throw phoneChangeErrorOf(e);
    }
  }
}

/// The backend's Thai `error` as it is, except for the two codes whose text
/// is English (`PHONE_IN_USE`, `OTP_MISMATCH`).
PhoneChangeException phoneChangeErrorOf(DioException e) {
  final res = e.response;
  final data = res?.data;
  final body = data is Map ? data : const {};
  final code = body['code']?.toString() ?? '';
  final text = body['error']?.toString() ?? '';
  final message = switch (code) {
    'PHONE_IN_USE' => PhoneChangeException.phoneInUse,
    'OTP_MISMATCH' => PhoneChangeException.codeMismatch,
    'INVALID_PHONE' when text.isEmpty => thaiPhoneHint,
    'INTERNAL' || '' => PhoneChangeException.fallback,
    _ => text.isEmpty ? PhoneChangeException.fallback : text,
  };
  Duration? retryAfter;
  if (code == 'OTP_RATE_LIMITED' || res?.statusCode == 429) {
    final raw = body['retry_after'];
    final secs = raw is num
        ? raw.toInt()
        : int.tryParse(res?.headers.value('retry-after') ?? '');
    if (secs != null && secs > 0) retryAfter = Duration(seconds: secs);
  }
  return PhoneChangeException(message, code: code, retryAfter: retryAfter);
}

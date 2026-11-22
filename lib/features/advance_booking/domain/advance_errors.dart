import 'package:dio/dio.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/advance_booking/domain/advance_ride.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';

/// A refusal from the advance booking endpoints: `{"code","error"}` with
/// 403 / 404 / 409 / 422. The Thai text is chosen by [code], never by the
/// server's words.
class AdvanceBookingException implements Exception {
  const AdvanceBookingException({this.status, this.code, this.cause});

  final int? status;
  final String? code;

  /// The original error, for the fallback message.
  final Object? cause;

  factory AdvanceBookingException.from(DioException e) {
    final data = e.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    return AdvanceBookingException(
      status: e.response?.statusCode,
      code: (code == null || code.isEmpty) ? null : code,
      cause: e,
    );
  }

  /// The ride is gone from this list (taken, released, not ours): refresh.
  bool get staleRide =>
      code == 'ALREADY_TAKEN' ||
      code == 'TOO_LATE' ||
      code == 'NOT_YOUR_RIDE' ||
      code == 'RIDE_NOT_FOUND';

  /// The driver can no longer use the board (re-read eligibility).
  bool get boardClosed =>
      code == 'NOT_ELIGIBLE' || code == 'SUSPENDED' || code == 'BOARD_OFF';

  /// Thai text for the driver. [ride] fills in times where a code needs one.
  /// An unknown 4xx gets a generic line: the server's `error` is often just
  /// the code itself, never meant for the driver.
  String messageFor({AdvanceRide? ride}) {
    if (advanceErrorText(code, ride: ride) case final text?) return text;
    final s = status ?? 0;
    if (s >= 400 && s < 500 && s != 401) return _fallback;
    return cause != null ? friendlyErrorMessage(cause!) : _fallback;
  }

  @override
  String toString() => 'AdvanceBookingException($status, $code)';
}

const _fallback = 'ทำรายการไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';

/// The Thai line for an advance booking refusal [code], or null for a code
/// this app doesn't know (the caller falls back to a generic line).
String? advanceErrorText(String? code, {AdvanceRide? ride}) {
  final rules = ride?.rules;
  return switch (code) {
    // Claim — 409
    'ALREADY_TAKEN' => 'มีคนขับรับงานนี้ไปแล้ว',
    'SCHEDULE_CONFLICT' => 'เวลางานนี้ชนกับงานจองที่คุณรับไว้แล้ว',
    'TOO_MANY_CLAIMS' =>
      'คุณรับงานจองไว้ครบจำนวนสูงสุดแล้ว ทำหรือคืนงานที่รับไว้ก่อน',
    'TOO_LATE' =>
      'งานนี้ใกล้เวลารับแล้ว ระบบกำลังหาคนขับแบบปกติ จึงรับจากบอร์ดไม่ได้',
    'VEHICLE_TYPE_NOT_YOURS' => 'งานนี้ไม่ตรงกับประเภทรถของคุณ',
    // Claim — 403
    'NOT_ELIGIBLE' => 'บัญชีของคุณยังรับงานจองล่วงหน้าไม่ได้',
    'SUSPENDED' => 'คุณถูกพักรับงานจองล่วงหน้าชั่วคราว',
    'BOARD_OFF' => 'ขณะนี้ปิดรับงานจองล่วงหน้า',
    'NOT_A_DRIVER' => 'บัญชีนี้ไม่ใช่บัญชีคนขับ',
    // Any action on one ride
    'RIDE_NOT_FOUND' => 'ไม่พบงานนี้แล้ว',
    'NOT_YOUR_RIDE' => 'งานนี้ไม่ได้อยู่กับคุณแล้ว',
    // Start — 409 / 422
    'NOT_YET' =>
      rules?.setOffFrom == null
          ? 'ยังไม่ถึงเวลากด "กำลังไป"'
          : 'ยังไม่ถึงเวลา กด "กำลังไป" ได้ตั้งแต่ '
                '${formatBangkokTime(rules!.setOffFrom!)}',
    'CANNOT_START' =>
      'ยังเริ่มงานนี้ไม่ได้ ตรวจสอบว่าออนไลน์อยู่ ไม่มีงานอื่นค้างอยู่ '
          'และเครดิตงานเงินสดยังไม่เต็ม',
    // No-show — 409
    'NO_SHOW_TOO_EARLY' => 'ยังไม่ครบเวลารอ กรุณารอผู้โดยสารต่ออีกสักครู่',
    'NOT_AT_PICKUP' => 'ต้องเลื่อน "ถึงจุดรับ" ก่อน จึงจะแจ้งว่าลูกค้าไม่มาได้',
    _ => null,
  };
}

/// [e] as an [AdvanceBookingException] when it is a refusal with a body,
/// otherwise unchanged.
Object asAdvanceError(Object e) => e is DioException && e.response != null
    ? AdvanceBookingException.from(e)
    : e;

/// Thai text for any error from these endpoints.
String advanceErrorMessage(Object e, {AdvanceRide? ride}) =>
    e is AdvanceBookingException
    ? e.messageFor(ride: ride)
    : friendlyErrorMessage(e);

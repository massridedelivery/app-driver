import 'package:dio/dio.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';

/// Converts any thrown error into a short, user-facing Thai message.
///
/// Never leak a raw [DioException] dump (status-code/validateStatus text) to the
/// UI — for anything network/server related we show a calm, actionable line and
/// keep the technical detail in logs only. Our own `Exception('ข้อความ...')`
/// (already user-friendly Thai) is passed through with the `Exception:` prefix
/// stripped.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง';
      case DioExceptionType.connectionError:
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาตรวจสอบสัญญาณแล้วลองใหม่';
      case DioExceptionType.badCertificate:
        return 'การเชื่อมต่อไม่ปลอดภัย กรุณาลองใหม่อีกครั้ง';
      case DioExceptionType.cancel:
        return 'ยกเลิกการดำเนินการแล้ว';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final code = error.response?.statusCode ?? 0;
        if (isCashJobBlockedError(error)) {
          return CashJobGate.defaultBlockedMessage;
        }
        if (code >= 500) {
          return 'เซิร์ฟเวอร์ขัดข้องชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง';
        }
        if (code == 401) return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        // 4xx: the backend's own reason, written in the phone's language
        // (Accept-Language) — shown as received. The fallbacks are for a
        // body with none.
        if (ApiError.serverMessage(error) case final msg?) return msg;
        if (code == 403) return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        if (code == 413) {
          return 'ไฟล์มีขนาดใหญ่เกินไป กรุณาเลือกไฟล์ที่เล็กลง';
        }
        return 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบแล้วลองใหม่';
    }
  }
  // Our own thrown Exception('...') carries a ready Thai message.
  final text = error.toString();
  return text.startsWith('Exception: ')
      ? text.substring('Exception: '.length)
      : 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
}

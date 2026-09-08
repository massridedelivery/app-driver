import 'package:dio/dio.dart';

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
        if (code >= 500) {
          return 'เซิร์ฟเวอร์ขัดข้องชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง';
        }
        if (code == 401 || code == 403) {
          return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        }
        if (code == 413) {
          return 'ไฟล์มีขนาดใหญ่เกินไป กรุณาเลือกไฟล์ที่เล็กลง';
        }
        // 4xx: the backend's own reason is usually meaningful — surface it if
        // present, otherwise fall back to a generic validation message.
        final data = error.response?.data;
        if (data is Map) {
          final msg = (data['message'] ?? data['error'])?.toString();
          if (msg != null && msg.trim().isNotEmpty) return msg;
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

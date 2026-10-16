import 'package:dio/dio.dart';

/// How a ride accept ended (BE #198).
enum AcceptOutcome {
  /// We hold the job — go to the live screen.
  accepted,

  /// Another driver got it first (409 `job_taken`). Not a cancellation.
  taken,

  /// Couldn't tell or it failed; the driver may try again.
  failed,
}

/// 409 `{"code":"job_taken"}` from POST /api/driver/jobs/:id/accept.
bool isJobTakenError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return error.response?.statusCode == 409 &&
      data is Map &&
      data['code']?.toString() == 'job_taken';
}

/// Message for an accept that didn't land.
String acceptOutcomeMessage(AcceptOutcome o) => switch (o) {
  AcceptOutcome.taken => 'มีคนรับงานนี้ไปแล้ว',
  AcceptOutcome.failed => 'รับงานไม่สำเร็จ กรุณาลองใหม่',
  AcceptOutcome.accepted => '',
};

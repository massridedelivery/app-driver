import 'package:dio/dio.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';

/// How a ride accept ended (BE #198).
enum AcceptOutcome {
  /// We hold the job — go to the live screen.
  accepted,

  /// Another driver got it first (409 `job_taken`). Not a cancellation.
  taken,

  /// The offer is gone for this driver: 403 "not offered to you", or a food
  /// order that was taken or cancelled as they accepted it (409, BE
  /// v1.6.26). Close the offer and show the backend's message.
  unavailable,

  /// Couldn't tell or it failed; the driver may try again.
  failed,

  /// 403: a cash job while the wallet is below the cash-job limit (BE
  /// dev115). Close the offer and point to "เติมเครดิต".
  cashBlocked,
}

/// 409 `{"code":"job_taken"}` from POST /api/driver/jobs/:id/accept.
bool isJobTakenError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return error.response?.statusCode == 409 &&
      data is Map &&
      data['code']?.toString() == 'job_taken';
}

/// 409 / 403 on an accept that a retry can't fix (BE v1.6.26): 409 "taken"
/// or, for food, "this order is no longer available"; 403 "this job was not
/// offered to you". The cash-job 403 is told apart by the caller first.
bool isOfferGoneError(Object error) {
  if (error is! DioException) return false;
  final code = error.response?.statusCode;
  return code == 409 || code == 403;
}

/// How a failed food accept ends: the cash-job 403 first, then any other
/// 409 / 403 (taken, ended, not offered), else [AcceptOutcome.failed].
AcceptOutcome foodAcceptOutcomeOf(Object error) {
  if (isCashJobBlockedError(error)) return AcceptOutcome.cashBlocked;
  if (isOfferGoneError(error)) return AcceptOutcome.unavailable;
  return AcceptOutcome.failed;
}

/// What to tell the driver when an accept didn't land: the backend's own
/// message (in the phone's language) when it sent one, else ours.
String acceptFailureMessage(AcceptOutcome o, Object? error) =>
    (error is DioException ? ApiError.serverMessage(error) : null) ??
    acceptOutcomeMessage(o);

/// Message for an accept that didn't land.
String acceptOutcomeMessage(AcceptOutcome o) => switch (o) {
  AcceptOutcome.taken => 'มีคนรับงานนี้ไปแล้ว',
  AcceptOutcome.unavailable => 'งานนี้ไม่สามารถรับได้แล้ว',
  AcceptOutcome.failed => 'รับงานไม่สำเร็จ กรุณาลองใหม่',
  AcceptOutcome.cashBlocked => CashJobGate.defaultBlockedMessage,
  AcceptOutcome.accepted => '',
};

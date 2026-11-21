import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/features/food_live/domain/food_order.dart';

/// A ride / food job the driver is no longer on (BE #191), from any of: the
/// `job_status` WS frame, the `job_cancelled` / `job_completed_by_admin`
/// push, or a 409 `job_cancelled` answer to a status update. Usually a
/// cancellation; [closedByAdmin] when the back office ended the ride as
/// COMPLETED while it was under way.
class JobCancelEvent {
  const JobCancelEvent(
    this.jobId, {
    this.cancelledBy,
    this.message,
    this.closedByAdmin = false,
  });

  final String jobId;

  /// `customer` | `admin` | `system`; null when the source doesn't say.
  final String? cancelledBy;

  /// What to tell the driver, when the source knows better than
  /// [jobCancelledMessage] (a food order that ended without delivery).
  final String? message;

  /// The back office ended the ride as COMPLETED mid-trip (BE 04baa9ef): not
  /// a cancellation, and the driver is already free for the next job.
  final bool closedByAdmin;
}

/// The dialog for a ride the back office closed (the backend's push text).
const jobClosedByAdminTitle = 'งานถูกปิดโดยผู้ดูแลระบบ';
const jobClosedByAdminMessage =
    'ผู้ดูแลระบบปิดงานนี้แล้ว คุณรับงานใหม่ได้ตามปกติ';

/// What the driver reads when the job they're on is cancelled.
String jobCancelledMessage(String? cancelledBy, {bool food = false}) =>
    switch (cancelledBy?.toLowerCase()) {
      'customer' => food ? 'งานถูกยกเลิกโดยลูกค้า' : 'งานถูกยกเลิกโดยผู้โดยสาร',
      'admin' => 'งานถูกยกเลิกโดยแอดมิน',
      'system' => 'งานถูกยกเลิกโดยระบบ',
      _ => 'งานนี้ถูกยกเลิกแล้ว',
    };

/// A WS frame cancelling a job: `job_status` (or food's
/// `ORDER_STATUS_UPDATED`) with status CANCELLED, fields top-level or under
/// `data`; or a food order ending under the driver (BE v1.6.26:
/// `order_cancelled` with CANCELLED / FAILED_DELIVERY / …, the back office's
/// `externally_dispatched` or `status_updated`). A ride's `job_status`
/// COMPLETED is the back office closing it, unless the driver completed it
/// themselves ([JobCancellations.markOwnCompletion]). Null for anything else.
JobCancelEvent? jobCancelFromSocket(
  String type,
  Map<String, dynamic> raw,
  Map<String, dynamic>? data,
) {
  if (foodFrameOf(type, raw, data) case final f?
      when isFoodOrderEndedFrame(type, f.status)) {
    return JobCancelEvent(f.orderId, message: foodOrderEndedMessage(f.status));
  }
  if (type != 'job_status' && type != 'ORDER_STATUS_UPDATED') return null;
  Object? read(String k) => raw[k] ?? data?[k];
  final status = read('status')?.toString().toUpperCase();
  final closed = type == 'job_status' && status == 'COMPLETED';
  if (status != 'CANCELLED' && !closed) return null;
  final id = (read('job_id') ?? read('orderId') ?? read('order_id'))
      ?.toString();
  if (id == null || id.isEmpty) return null;
  if (closed) return JobCancelEvent(id, closedByAdmin: true);
  return JobCancelEvent(id, cancelledBy: read('cancelled_by')?.toString());
}

/// The `job_cancelled` push (`data.type`, `job_id`, `cancelled_by`), or
/// `job_completed_by_admin` (`job_id`) for a ride the back office closed.
JobCancelEvent? jobCancelFromPush(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  if (type != 'job_cancelled' && type != 'job_completed_by_admin') return null;
  final id = data['job_id']?.toString();
  if (id == null || id.isEmpty) return null;
  if (type == 'job_completed_by_admin') {
    return JobCancelEvent(id, closedByAdmin: true);
  }
  return JobCancelEvent(id, cancelledBy: data['cancelled_by']?.toString());
}

/// PATCH /api/driver/jobs/{id}/status on a job that's already cancelled:
/// 409 `{"code":"job_cancelled"}`. Retrying can't help.
bool isJobCancelledError(Object error) {
  // Through BaseApiService the DioException arrives as an ApiException that
  // keeps the HTTP status; this endpoint answers 409 only for a cancelled job.
  if (error is ApiException) return error.code == 409;
  if (error is! DioException) return false;
  final data = error.response?.data;
  return error.response?.statusCode == 409 &&
      data is Map &&
      data['code']?.toString() == 'job_cancelled';
}

/// App-wide channel for [JobCancelEvent]s. The listener at the app root
/// closes the job screen once; repeats of the same job are dropped (the WS,
/// the push and a 409 can all report one cancellation).
class JobCancellations {
  JobCancellations._();
  static final JobCancellations instance = JobCancellations._();

  final _events = StreamController<JobCancelEvent>.broadcast();
  final _seen = <String>{};
  final _ownCompletions = <String>{};

  Stream<JobCancelEvent> get events => _events.stream;

  /// The driver is completing [jobId] themselves (the COMPLETED status
  /// PATCH): the `job_status` COMPLETED frame that follows is theirs, not the
  /// back office's. Call before sending, since the frame can beat the reply.
  void markOwnCompletion(String jobId) => _ownCompletions.add(jobId);

  /// The driver's COMPLETED didn't go through: a close is the office's again.
  void clearOwnCompletion(String jobId) => _ownCompletions.remove(jobId);

  void report(JobCancelEvent e) {
    if (e.closedByAdmin && _ownCompletions.contains(e.jobId)) return;
    if (!_seen.add(e.jobId)) return;
    _events.add(e);
  }

  @visibleForTesting
  void debugReset() {
    _seen.clear();
    _ownCompletions.clear();
  }
}

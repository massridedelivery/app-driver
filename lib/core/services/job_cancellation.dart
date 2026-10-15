import 'dart:async';

import 'package:dio/dio.dart';

/// A ride / food job the backend says is cancelled (BE #191), from any of:
/// the `job_status` WS frame, the `job_cancelled` push, or a 409
/// `job_cancelled` answer to a status update.
class JobCancelEvent {
  const JobCancelEvent(this.jobId, {this.cancelledBy});

  final String jobId;

  /// `customer` | `admin` | `system`; null when the source doesn't say.
  final String? cancelledBy;
}

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
/// `data`. Null for anything else.
JobCancelEvent? jobCancelFromSocket(
  String type,
  Map<String, dynamic> raw,
  Map<String, dynamic>? data,
) {
  if (type != 'job_status' && type != 'ORDER_STATUS_UPDATED') return null;
  Object? read(String k) => raw[k] ?? data?[k];
  if (read('status')?.toString().toUpperCase() != 'CANCELLED') return null;
  final id = (read('job_id') ?? read('orderId') ?? read('order_id'))
      ?.toString();
  if (id == null || id.isEmpty) return null;
  return JobCancelEvent(id, cancelledBy: read('cancelled_by')?.toString());
}

/// The `job_cancelled` push (`data.type`, `job_id`, `cancelled_by`).
JobCancelEvent? jobCancelFromPush(Map<String, dynamic> data) {
  if (data['type']?.toString() != 'job_cancelled') return null;
  final id = data['job_id']?.toString();
  if (id == null || id.isEmpty) return null;
  return JobCancelEvent(id, cancelledBy: data['cancelled_by']?.toString());
}

/// PATCH /api/driver/jobs/{id}/status on a job that's already cancelled:
/// 409 `{"code":"job_cancelled"}`. Retrying can't help.
bool isJobCancelledError(Object error) {
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

  Stream<JobCancelEvent> get events => _events.stream;

  void report(JobCancelEvent e) {
    if (!_seen.add(e.jobId)) return;
    _events.add(e);
  }
}

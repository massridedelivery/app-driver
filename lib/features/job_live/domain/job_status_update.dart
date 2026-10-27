import 'package:dio/dio.dart';
import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/core/managers/api/app_exception.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';

/// How a ride status change ended.
enum JobStatusOutcome {
  /// The backend took it — move the screen on.
  ok,

  /// ARRIVED_AT_PICK_UP needs a GPS fix and there was none.
  noLocation,

  /// The backend refused (e.g. too far from the pickup). Stay put.
  refused,

  /// 409 job_cancelled: run the cancellation flow.
  cancelled,
}

class JobStatusResult {
  const JobStatusResult(this.outcome, [this.message = '']);

  final JobStatusOutcome outcome;

  /// Thai copy for the driver when not [JobStatusOutcome.ok].
  final String message;

  bool get ok => outcome == JobStatusOutcome.ok;
}

const noLocationMessage = 'ไม่พบตำแหน่งปัจจุบัน กรุณาเปิด GPS แล้วลองใหม่';

/// The backend's arrival refusal (WAITING-FEE-001) in Thai:
/// "too far from pickup point to mark as arrived (350m away, limit 200m)"
/// → "ยังอยู่ห่างจุดรับเกิน 200 เมตร (ห่าง 350 เมตร) กรุณาเข้าใกล้จุดรับก่อน".
/// "location coordinates are required…" → [noLocationMessage]. Anything else
/// is passed through (or a generic line when empty).
String statusErrorMessage(String backend) {
  final lower = backend.toLowerCase();
  if (lower.contains('too far')) {
    final away = RegExp(r'(\d+(?:\.\d+)?)\s*m\s*away').firstMatch(lower);
    final limit = RegExp(r'limit\s*(\d+(?:\.\d+)?)\s*m').firstMatch(lower);
    if (away != null && limit != null) {
      String m(String v) => double.parse(v).round().toString();
      return 'ยังอยู่ห่างจุดรับเกิน ${m(limit.group(1)!)} เมตร '
          '(ห่าง ${m(away.group(1)!)} เมตร) กรุณาเข้าใกล้จุดรับก่อน';
    }
    return 'ยังอยู่ห่างจุดรับเกินระยะที่กำหนด กรุณาเข้าใกล้จุดรับก่อน';
  }
  if (lower.contains('location coordinates are required')) {
    return noLocationMessage;
  }
  final t = backend.trim();
  return t.isEmpty ? 'อัปเดตสถานะงานไม่สำเร็จ กรุณาลองใหม่' : t;
}

/// Sends a ride status over REST (PATCH /api/driver/jobs/:id/status) and
/// reports how it went, so the screen moves only once the backend agrees.
/// ARRIVED_AT_PICK_UP must carry the driver's position (the backend checks
/// the arrival radius); other statuses send it when there is one.
Future<JobStatusResult> sendJobStatus({
  required JobLiveRepository repo,
  required String jobId,
  required String status,
  required Future<({double lat, double lng})?> Function() locate,
}) async {
  final needsFix = status == 'ARRIVED_AT_PICK_UP';
  final at = await locate();
  if (needsFix && at == null) {
    return const JobStatusResult(
      JobStatusOutcome.noLocation,
      noLocationMessage,
    );
  }
  try {
    await repo.updateJobStatus(jobId, {
      'status': status,
      if (at != null) 'lat': at.lat,
      if (at != null) 'lng': at.lng,
    });
    return const JobStatusResult(JobStatusOutcome.ok);
  } catch (e) {
    if (isJobCancelledError(e)) {
      return const JobStatusResult(JobStatusOutcome.cancelled);
    }
    var backend = '';
    if (e is ApiException) {
      backend = e.message ?? '';
    } else if (e is AppException) {
      backend = 'เชื่อมต่อไม่สำเร็จ กรุณาลองใหม่';
    } else if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        backend = (data['error'] ?? data['message'] ?? '').toString();
      }
      if (backend.isEmpty && e.response == null) {
        backend = 'เชื่อมต่อไม่สำเร็จ กรุณาลองใหม่';
      }
    }
    final message = statusErrorMessage(backend);
    return JobStatusResult(
      message == noLocationMessage
          ? JobStatusOutcome.noLocation
          : JobStatusOutcome.refused,
      message,
    );
  }
}

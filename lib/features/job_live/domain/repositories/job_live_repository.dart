import 'package:massdrive/features/job_live/domain/models/active_item.dart';

abstract class JobLiveRepository {
  Future<void> cancelJob(String jobId, Map<String, dynamic> data);
  Future<void> arriveAtStop(String jobId, String stopId);
  Future<void> departFromStop(String jobId, String stopId);
  Future<void> updateJobStatus(String jobId, Map<String, dynamic> data);
  Future<void> acceptJob(String jobId);

  /// Cross-vertical active index (SCRUM-45). Returns `[]` when idle.
  Future<List<ActiveItem>> getActiveSummary();

  /// A ride's status now (GET /api/driver/jobs/:id), upper-case; null when
  /// it can't be read.
  Future<String?> getJobStatus(String jobId);

  Future<dynamic> getActiveJob({double? lat, double? lng});
  Future<dynamic> getActiveOffer({double? lat, double? lng});
  Future<dynamic> getActiveFoodOrder({double? lat, double? lng});
}

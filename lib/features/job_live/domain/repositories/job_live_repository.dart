abstract class JobLiveRepository {
  Future<void> cancelJob(String jobId, Map<String, dynamic> data);
  Future<void> arriveAtStop(String jobId, String stopId);
  Future<void> departFromStop(String jobId, String stopId);
  Future<void> updateJobStatus(String jobId, Map<String, dynamic> data);
  Future<dynamic> getActiveJob();
  Future<dynamic> getActiveOffer();
  Future<dynamic> getActiveFoodOrder();
}

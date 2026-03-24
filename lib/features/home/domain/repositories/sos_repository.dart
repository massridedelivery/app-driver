abstract class SosRepository {
  Future<void> triggerSos(Map<String, dynamic> data);
  Future<void> resolveSos(String incidentId, Map<String, dynamic> data);
}

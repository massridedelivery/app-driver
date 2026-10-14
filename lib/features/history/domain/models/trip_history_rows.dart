import 'history_item_model.dart';

/// The trip-history list shows only what belongs to a trip — fares,
/// commissions — each tagged with the job's vehicle type for its icon.
/// Top-ups / adjustments / withdrawals are left out: they have their own
/// history screens.
List<HistoryItemModel> tripRows(
  Iterable<HistoryItemModel> raw,
  Map<String, String> vehicleByJob,
) => raw
    .where((i) => i.isTripEntry)
    .map((i) => i.withVehicleType(vehicleByJob[i.jobId]))
    .toList();

/// What the trip list (`GET /api/driver/earnings/trips`) knows about a job:
/// its vehicle type and the backend-resolved whole-baht net.
class TripSummary {
  const TripSummary({this.vehicleTypeName, this.driverNet});

  /// `driver_info.vehicle_type_name` (or a top-level `vehicle_type_name`).
  final String? vehicleTypeName;

  /// `driver_net`; null until the trip settles.
  final int? driverNet;
}

/// job id → [TripSummary] from the trip list response.
Map<String, TripSummary> tripSummariesByJob(Object? response) {
  final list = response is Map ? response['data'] : null;
  if (list is! List) return const {};
  final out = <String, TripSummary>{};
  for (final t in list.whereType<Map>()) {
    final id = t['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final info = t['driver_info'];
    final name =
        (info is Map ? info['vehicle_type_name'] : null) ??
        t['vehicle_type_name'];
    final net = t['driver_net'];
    out[id] = TripSummary(
      vehicleTypeName: name?.toString(),
      driverNet: net is num ? net.round() : null,
    );
  }
  return out;
}

/// job id → vehicle type name (jobs without one are left out).
Map<String, String> vehicleTypesByJob(Object? response) => {
  for (final e in tripSummariesByJob(response).entries)
    if (e.value.vehicleTypeName != null) e.key: e.value.vehicleTypeName!,
};

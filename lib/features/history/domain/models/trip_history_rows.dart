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

/// job id → vehicle type name from `GET /api/driver/earnings/trips`
/// (`driver_info.vehicle_type_name`, or a top-level `vehicle_type_name`).
Map<String, String> vehicleTypesByJob(Object? response) {
  final list = response is Map ? response['data'] : null;
  if (list is! List) return const {};
  final out = <String, String>{};
  for (final t in list.whereType<Map>()) {
    final id = t['id']?.toString();
    final info = t['driver_info'];
    final name =
        (info is Map ? info['vehicle_type_name'] : null) ??
        t['vehicle_type_name'];
    if (id != null && id.isNotEmpty && name != null) {
      out[id] = name.toString();
    }
  }
  return out;
}

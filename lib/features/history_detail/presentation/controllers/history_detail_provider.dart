import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

double _d(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? (double.tryParse(v) ?? 0) : 0);
String _s(dynamic v) => v?.toString() ?? '';
int? _int(dynamic v) => v is num ? v.round() : null;

List<Map<String, dynamic>> _list(dynamic v, String key) {
  if (v is Map && v[key] is List) {
    return (v[key] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

/// Loads a completed trip's detail by its job/trip id from the trip list
/// (GET /api/driver/earnings/trips), which carries addresses, coords, distance
/// and the backend-resolved whole-baht gross_fare / commission / driver_net.
///
/// There is no per-id detail endpoint, so the list is fetched and matched on
/// the id locally. Returns null when no trip matches (e.g. a top-up/withdrawal
/// row) so the screen can show a friendly "no trip detail" message.
final historyDetailProvider = FutureProvider.autoDispose
    .family<HistoryDetailEntity?, String>((ref, jobId) async {
  if (jobId.isEmpty) return null;
  final dio = getIt<Dio>();
  // The default page is only 10 trips; older ones would show "no detail".
  final res = await dio.get(
    Endpoints.driverEarningsTrips,
    queryParameters: {'limit': 100},
  );

  final trips = _list(res.data, 'data');
  Map<String, dynamic>? trip;
  for (final t in trips) {
    if (_s(t['id']) == jobId) {
      trip = t;
      break;
    }
  }
  if (trip == null) return null;
  return historyDetailFromTrip(trip);
});

/// Maps one `GET /api/driver/earnings/trips` row to the detail screen's data.
HistoryDetailEntity historyDetailFromTrip(Map<String, dynamic> trip) {
  final fare = _d(trip['fare']);
  // updated_at moves on any later write (rating, settlement…), so only the
  // real completion time gives a trustworthy duration.
  final accepted = DateTime.tryParse(_s(trip['accepted_at']));
  final ended = DateTime.tryParse(_s(trip['completed_at']));
  final duration = (accepted != null && ended != null)
      ? ended.difference(accepted).inMinutes
      : null;

  return HistoryDetailEntity(
    id: _s(trip['id']),
    dateTime: DateTime.tryParse(_s(trip['created_at'])) ?? DateTime.now(),
    pickupAddress: _s(trip['pickup_address']),
    dropoffAddress: _s(trip['dropoff_address']),
    distanceKm: _d(trip['distance_km']),
    durationMinute: duration == null || duration < 0 ? null : duration,
    total: double.parse(fare.toStringAsFixed(2)),
    paymentMethod: _paymentLabel(_s(trip['payment_method'])),
    driverNet: (_int(trip['driver_net']) ?? 0).toDouble(),
    grossFare: _int(trip['gross_fare']),
    commission: _int(trip['commission']),
    settledNet: _int(trip['driver_net']),
    serviceType: 'ride',
    pickupLat: trip['pickup_lat'] == null ? null : _d(trip['pickup_lat']),
    pickupLng: trip['pickup_lng'] == null ? null : _d(trip['pickup_lng']),
    dropoffLat: trip['dropoff_lat'] == null
        ? null
        : _d(trip['dropoff_lat']),
    dropoffLng: trip['dropoff_lng'] == null
        ? null
        : _d(trip['dropoff_lng']),
  );
}

String _paymentLabel(String raw) {
  switch (raw.toUpperCase()) {
    case 'PROMPTPAY':
    case 'QR':
    case 'QR_PAYMENT':
      return 'พร้อมเพย์ / QR';
    case 'CASH':
      return 'เงินสด';
    case 'CARD':
    case 'CREDIT_CARD':
      return 'บัตรเครดิต';
    default:
      return raw.isEmpty ? '-' : raw;
  }
}

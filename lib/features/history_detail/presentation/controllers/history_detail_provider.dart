import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

double _d(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? (double.tryParse(v) ?? 0) : 0);
String _s(dynamic v) => v?.toString() ?? '';

List<Map<String, dynamic>> _list(dynamic v, String key) {
  if (v is Map && v[key] is List) {
    return (v[key] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

/// Loads a completed trip's detail by its job/trip id. Combines the trip record
/// (addresses, coords, distance, fare — GET /api/driver/earnings/trips) with
/// its wallet transactions (driver net — GET /api/driver/earnings/transactions).
///
/// There is no per-id detail endpoint, so both lists are fetched and matched on
/// the id locally. Returns null when no trip matches (e.g. a top-up/withdrawal
/// row) so the screen can show a friendly "no trip detail" message.
final historyDetailProvider = FutureProvider.autoDispose
    .family<HistoryDetailEntity?, String>((ref, jobId) async {
  if (jobId.isEmpty) return null;
  final dio = getIt<Dio>();
  final results = await Future.wait([
    dio.get(Endpoints.driverEarningsTrips),
    dio.get(Endpoints.driverEarningsTransactions),
  ]);

  final trips = _list(results[0].data, 'data');
  Map<String, dynamic>? trip;
  for (final t in trips) {
    if (_s(t['id']) == jobId) {
      trip = t;
      break;
    }
  }
  if (trip == null) return null;

  // Driver net = sum of this job's wallet transactions (fare in, commission out).
  final txns = _list(results[1].data, 'transactions');
  double net = 0;
  var hasTxn = false;
  for (final tx in txns) {
    if (_s(tx['job_id']) == jobId) {
      net += _d(tx['amount']);
      hasTxn = true;
    }
  }

  final fare = _d(trip['fare']);
  final accepted = DateTime.tryParse(_s(trip['accepted_at']));
  final ended = DateTime.tryParse(_s(trip['updated_at']));
  final duration = (accepted != null && ended != null)
      ? ended.difference(accepted).inMinutes
      : 0;

  return HistoryDetailEntity(
    id: _s(trip['id']),
    dateTime: DateTime.tryParse(_s(trip['created_at'])) ?? DateTime.now(),
    pickupAddress: _s(trip['pickup_address']),
    dropoffAddress: _s(trip['dropoff_address']),
    distanceKm: _d(trip['distance_km']),
    durationMinute: duration < 0 ? 0 : duration,
    total: double.parse(fare.toStringAsFixed(2)),
    paymentMethod: _paymentLabel(_s(trip['payment_method'])),
    driverNet: double.parse((hasTxn ? net : fare).toStringAsFixed(2)),
    serviceType: 'ride',
    pickupLat: trip['pickup_lat'] == null ? null : _d(trip['pickup_lat']),
    pickupLng: trip['pickup_lng'] == null ? null : _d(trip['pickup_lng']),
    dropoffLat: trip['dropoff_lat'] == null ? null : _d(trip['dropoff_lat']),
    dropoffLng: trip['dropoff_lng'] == null ? null : _d(trip['dropoff_lng']),
  );
});

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

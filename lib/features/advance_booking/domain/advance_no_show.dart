import 'package:flutter/foundation.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';

/// What the live ride screen needs for "ลูกค้าไม่มา", read from the job of
/// `GET /api/driver/jobs/active`: a ride booked ahead carries
/// `advance_policy` (with `wait_minutes`), `scheduled_at` and, once arrived,
/// `arrived_at_pickup_at`.
@immutable
class AdvanceLiveRide {
  const AdvanceLiveRide({
    required this.jobId,
    required this.scheduledAt,
    required this.waitMinutes,
    this.arrivedAt,
    this.flightNumber,
  });

  final String jobId;
  final DateTime scheduledAt;

  /// The policy the ride was booked under (45 at an airport).
  final int waitMinutes;
  final DateTime? arrivedAt;
  final String? flightNumber;

  /// Null for a ride not booked ahead (no `advance_policy`) or without a
  /// pickup time.
  static AdvanceLiveRide? fromJobJson(Map<String, dynamic> j) {
    final policy = j['advance_policy'];
    if (policy is! Map) return null;
    final at = parseAdvanceTime(j['scheduled_at']);
    final id = j['id']?.toString() ?? '';
    if (at == null || id.isEmpty) return null;
    final wait = policy['wait_minutes'];
    final flight = policy['flight_number']?.toString().trim();
    return AdvanceLiveRide(
      jobId: id,
      scheduledAt: at,
      waitMinutes: wait is num ? wait.round() : int.tryParse('$wait') ?? 0,
      arrivedAt: parseAdvanceTime(j['arrived_at_pickup_at']),
      flightNumber: (flight == null || flight.isEmpty) ? null : flight,
    );
  }

  /// When "ลูกค้าไม่มา" opens: [waitMinutes] after the pickup time or the
  /// arrival, whichever is later (the backend's rule). [arrivedFallback] is
  /// used while the server's arrival time is not known yet.
  DateTime noShowFrom({DateTime? arrivedFallback}) {
    final arrived = arrivedAt ?? arrivedFallback;
    final start = arrived != null && arrived.isAfter(scheduledAt)
        ? arrived
        : scheduledAt;
    return start.add(Duration(minutes: waitMinutes));
  }

  bool noShowOpenAt(DateTime now, {DateTime? arrivedFallback}) =>
      !now.isBefore(noShowFrom(arrivedFallback: arrivedFallback));

  /// The muted line while waiting.
  String waitingHint({DateTime? arrivedFallback}) =>
      'งานจองล่วงหน้า · รอผู้โดยสาร $waitMinutes นาที'
      ' · แจ้ง "ลูกค้าไม่มา" ได้ตั้งแต่ '
      '${formatBangkokTime(noShowFrom(arrivedFallback: arrivedFallback))}';
}

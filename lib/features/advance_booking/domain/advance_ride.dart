import 'package:flutter/foundation.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';

/// A ride booked ahead, as the board (`GET /api/driver/advance-jobs`) and
/// "งานของฉัน" (`GET /api/driver/advance-jobs/mine`) list it — the backend's
/// `advanceboard.Ride`. Every figure is the backend's; nothing is computed
/// here except comparing [rules] times with the clock.
@immutable
class AdvanceRide {
  const AdvanceRide({
    required this.id,
    required this.scheduledAt,
    this.vehicleTypeId = '',
    this.vehicleType = '',
    this.pickupLat = 0,
    this.pickupLng = 0,
    this.pickupAddress = '',
    this.dropoffLat = 0,
    this.dropoffLng = 0,
    this.dropoffAddress = '',
    this.distanceKm = 0,
    this.durationMin = 0,
    this.fare = 0,
    this.advanceFee = 0,
    this.paymentMethod = '',
    this.flightNumber,
    this.distanceFromYouKm,
    this.earnings,
    this.rules,
    this.conflict = false,
    this.reservedAt,
  });

  final String id;

  /// Pickup time (UTC).
  final DateTime scheduledAt;
  final String vehicleTypeId;

  /// The vehicle type's display name ("รถยนต์ 4 ที่นั่ง").
  final String vehicleType;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;

  /// The trip, pickup → drop-off.
  final double distanceKm;
  final double durationMin;
  final double fare;
  final double advanceFee;

  /// `CASH`, `PROMPTPAY`, …
  final String paymentMethod;

  /// `policy.flight_number`: an airport pickup's arriving flight (shown, not
  /// tracked). Null for other rides.
  final String? flightNumber;

  /// Straight line from the driver to the pickup; only on the board, and
  /// only when the app sent lat/lng.
  final double? distanceFromYouKm;
  final AdvanceEarnings? earnings;
  final AdvanceRules? rules;

  /// It overlaps a ride the driver already holds: shown greyed, not
  /// claimable.
  final bool conflict;

  /// When the driver claimed it (mine).
  final DateTime? reservedAt;

  bool get isAirport => flightNumber != null;

  factory AdvanceRide.fromJson(Map<String, dynamic> j) {
    final policy = j['policy'];
    final flight = policy is Map ? _str(policy['flight_number']) : null;
    final earnings = j['estimated_earnings'];
    final rules = j['rules'];
    return AdvanceRide(
      id: _str(j['id']) ?? '',
      scheduledAt:
          parseAdvanceTime(j['scheduled_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      vehicleTypeId: _str(j['vehicle_type_id']) ?? '',
      vehicleType: _str(j['vehicle_type']) ?? '',
      pickupLat: _num(j['pickup_lat']),
      pickupLng: _num(j['pickup_lng']),
      pickupAddress: _str(j['pickup_address']) ?? '',
      dropoffLat: _num(j['dropoff_lat']),
      dropoffLng: _num(j['dropoff_lng']),
      dropoffAddress: _str(j['dropoff_address']) ?? '',
      distanceKm: _num(j['distance_km']),
      durationMin: _num(j['duration_min']),
      fare: _num(j['fare']),
      advanceFee: _num(j['advance_booking_fee']),
      paymentMethod: _str(j['payment_method']) ?? '',
      flightNumber: flight,
      distanceFromYouKm: j['distance_from_you_km'] == null
          ? null
          : _num(j['distance_from_you_km']),
      earnings: earnings is Map
          ? AdvanceEarnings.fromJson(Map<String, dynamic>.from(earnings))
          : null,
      rules: rules is Map
          ? AdvanceRules.fromJson(Map<String, dynamic>.from(rules))
          : null,
      conflict: j['conflict'] == true,
      reservedAt: parseAdvanceTime(j['reserved_at']),
    );
  }

  /// A list response; anything that isn't a ride object is skipped.
  static List<AdvanceRide> listFrom(Object? data) => [
    for (final r in (data is List ? data : const []))
      if (r is Map) AdvanceRide.fromJson(Map<String, dynamic>.from(r)),
  ];
}

/// `estimated_earnings`: the fare less this driver's commission plus their
/// share of the advance booking fee — an estimate (waiting and tolls come on
/// top).
@immutable
class AdvanceEarnings {
  const AdvanceEarnings({this.net = 0, this.feeShare = 0, this.commission = 0});

  final double net;
  final double feeShare;
  final double commission;

  factory AdvanceEarnings.fromJson(Map<String, dynamic> j) => AdvanceEarnings(
    net: _num(j['net']),
    feeShare: _num(j['advance_fee_share']),
    commission: _num(j['commission']),
  );
}

/// `rules`: the claim's rules in the driver's words.
@immutable
class AdvanceRules {
  const AdvanceRules({
    this.freeReleaseUntil,
    this.lateReleaseFee = 0,
    this.setOffFrom,
    this.setOffBy,
    this.waitMinutes = 0,
  });

  /// Giving the ride back is free until then.
  final DateTime? freeReleaseUntil;

  /// Taken from the wallet for a release after [freeReleaseUntil].
  final double lateReleaseFee;

  /// "กำลังไป" opens then…
  final DateTime? setOffFrom;

  /// …and must be pressed by then, or the ride goes to another driver with
  /// the late fee.
  final DateTime? setOffBy;

  /// How long to wait at the pickup before "ลูกค้าไม่มา" (45 at airports).
  final int waitMinutes;

  factory AdvanceRules.fromJson(Map<String, dynamic> j) => AdvanceRules(
    freeReleaseUntil: parseAdvanceTime(j['free_release_until']),
    lateReleaseFee: _num(j['late_release_fee']),
    setOffFrom: parseAdvanceTime(j['set_off_from']),
    setOffBy: parseAdvanceTime(j['set_off_by']),
    waitMinutes: _num(j['wait_minutes']).round(),
  );
}

/// `POST …/:id/release` → `{free, penalty, back_on_board}`.
@immutable
class AdvanceReleaseResult {
  const AdvanceReleaseResult({
    required this.free,
    this.penalty = 0,
    this.backOnBoard = false,
  });

  final bool free;
  final double penalty;

  /// Offered on the board again; otherwise searched for in real time.
  final bool backOnBoard;

  factory AdvanceReleaseResult.fromJson(Map<String, dynamic> j) =>
      AdvanceReleaseResult(
        free: j['free'] == true,
        penalty: _num(j['penalty']),
        backOnBoard: j['back_on_board'] == true,
      );

  /// The snackbar after giving a ride back.
  String get message {
    final fee = !free && penalty > 0
        ? 'คืนงานแล้ว หักค่าปรับ ${formatBaht(penalty)}'
        : 'คืนงานแล้ว ไม่มีค่าปรับ';
    final where = backOnBoard
        ? 'งานกลับไปอยู่บนบอร์ดให้คนขับคนอื่น'
        : 'ระบบกำลังหาคนขับคนอื่นให้ลูกค้า';
    return '$fee · $where';
  }
}

// ── Release: what the confirm sheet says ────────────────────────────────

/// What giving [rules]' ride back costs at [now], from the rules alone (the
/// server decides; this only words the confirmation).
@immutable
class ReleaseTerms {
  const ReleaseTerms({required this.free, required this.fee, this.freeUntil});

  final bool free;
  final double fee;
  final DateTime? freeUntil;

  /// The sheet's main line.
  String get headline {
    if (free) {
      return freeUntil == null
          ? 'คืนงานตอนนี้ไม่มีค่าปรับ'
          : 'คืนฟรีถึง ${formatBangkokDateTime(freeUntil!)}';
    }
    return fee > 0
        ? 'คืนตอนนี้มีค่าปรับ ${formatBaht(fee)}'
        : 'เลยเวลาคืนฟรีแล้ว';
  }

  /// The line under it.
  String get detail {
    if (free) return 'คืนตอนนี้ไม่มีค่าปรับ งานจะกลับไปให้คนขับคนอื่น';
    final since = freeUntil == null
        ? 'เลยเวลาคืนฟรีแล้ว'
        : 'เลยเวลาคืนฟรี (${formatBangkokDateTime(freeUntil!)}) แล้ว';
    final money = fee > 0
        ? ' ค่าปรับ ${formatBaht(fee)} หักจากกระเป๋าเงิน'
        : '';
    return '$since$money และนับเป็นการคืนงานช้า';
  }

  /// The confirm button.
  String get confirmLabel =>
      !free && fee > 0 ? 'คืนงาน (ค่าปรับ ${formatBaht(fee)})' : 'คืนงาน';
}

ReleaseTerms releaseTermsAt(AdvanceRules? rules, DateTime now) {
  final until = rules?.freeReleaseUntil;
  final free = until == null || now.isBefore(until);
  return ReleaseTerms(
    free: free,
    fee: rules?.lateReleaseFee ?? 0,
    freeUntil: until,
  );
}

// ── Start ("กำลังไป") ────────────────────────────────────────────────────

enum StartWindow {
  /// Before rules.set_off_from: the button waits.
  notYet,

  /// Between set_off_from and set_off_by.
  open,

  /// Past set_off_by: still pressable (the server decides — the ride may
  /// already have gone to another driver).
  late,
}

StartWindow startWindowAt(AdvanceRules? rules, DateTime now) {
  final from = rules?.setOffFrom;
  final by = rules?.setOffBy;
  if (from != null && now.isBefore(from)) return StartWindow.notYet;
  if (by != null && now.isAfter(by)) return StartWindow.late;
  return StartWindow.open;
}

/// The line under a claimed ride's "กำลังไป" button.
String startHint(AdvanceRules? rules, DateTime now) {
  final from = rules?.setOffFrom;
  final by = rules?.setOffBy;
  return switch (startWindowAt(rules, now)) {
    StartWindow.notYet =>
      'กด "กำลังไป" ได้ตั้งแต่ ${formatBangkokDateTime(from!)}'
          '${by == null ? '' : ' · ต้องกดภายใน ${formatBangkokTime(by)}'}',
    StartWindow.open =>
      by == null
          ? 'กด "กำลังไป" ได้แล้ว'
          : 'กด "กำลังไป" ได้แล้ว · ต้องกดภายใน ${formatBangkokTime(by)}',
    StartWindow.late =>
      'เลยเวลากด "กำลังไป" (${formatBangkokTime(by!)}) แล้ว'
          ' งานอาจถูกส่งต่อให้คนขับคนอื่น',
  };
}

String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

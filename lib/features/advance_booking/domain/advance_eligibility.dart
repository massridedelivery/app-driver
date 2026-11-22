import 'package:flutter/foundation.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';

/// `GET /api/driver/advance-jobs/eligibility`: may this driver use the
/// board, and why not.
@immutable
class AdvanceEligibility {
  const AdvanceEligibility({
    required this.enabled,
    required this.eligible,
    this.reasons = const [],
    this.suspendedUntil,
    this.lateReleases30d = 0,
    this.maxLateReleases = 0,
    this.minRating = 0,
    this.minCompletedJobs = 0,
    this.rating = 0,
    this.completedJobs = 0,
  });

  final bool enabled;
  final bool eligible;

  /// BOARD_OFF, ACCOUNT_INACTIVE, NOT_VERIFIED, LOW_RATING, TOO_FEW_JOBS,
  /// NO_VEHICLE_TYPE, SUSPENDED (unknown codes kept as sent).
  final List<String> reasons;
  final DateTime? suspendedUntil;

  /// Late releases in the last 30 days; [maxLateReleases] of them suspend.
  final int lateReleases30d;
  final int maxLateReleases;
  final double minRating;
  final int minCompletedJobs;
  final double rating;
  final int completedJobs;

  factory AdvanceEligibility.fromJson(Map<String, dynamic> j) =>
      AdvanceEligibility(
        enabled: j['enabled'] == true,
        eligible: j['eligible'] == true,
        reasons: [
          for (final r in (j['reasons'] is List ? j['reasons'] as List : []))
            if (r != null && r.toString().isNotEmpty) r.toString(),
        ],
        suspendedUntil: parseAdvanceTime(j['suspended_until']),
        lateReleases30d: _int(j['late_releases_30d']),
        maxLateReleases: _int(j['max_late_releases']),
        minRating: _num(j['min_rating']),
        minCompletedJobs: _int(j['min_completed_jobs']),
        rating: _num(j['rating']),
        completedJobs: _int(j['completed_jobs']),
      );

  /// One Thai line per reason, in the order the backend sent them.
  List<String> get reasonLines => [for (final r in reasons) reasonText(r)];

  /// The Thai explanation of one [reason] code (never the raw code).
  String reasonText(String reason) => switch (reason) {
    'BOARD_OFF' => 'ขณะนี้ยังไม่เปิดรับงานจองล่วงหน้า',
    'ACCOUNT_INACTIVE' =>
      'บัญชีของคุณถูกระงับหรือยังไม่เปิดใช้งาน กรุณาติดต่อเจ้าหน้าที่',
    'NOT_VERIFIED' => 'บัญชียังไม่ผ่านการตรวจสอบเอกสาร',
    'LOW_RATING' =>
      'คะแนนของคุณ ${_rating(rating)} ต่ำกว่าเกณฑ์ ${_rating(minRating)}',
    'TOO_FEW_JOBS' =>
      'ต้องวิ่งงานสำเร็จอย่างน้อย $minCompletedJobs งาน '
          '(ตอนนี้ $completedJobs งาน)',
    'NO_VEHICLE_TYPE' => 'ยังไม่ได้เลือกประเภทรถที่ให้บริการ',
    'SUSPENDED' =>
      suspendedUntil == null
          ? 'ถูกพักรับงานจองล่วงหน้าชั่วคราว เพราะคืนงานหลังเวลาฟรีบ่อยเกินไป'
          : 'ถูกพักรับงานจองล่วงหน้าถึง '
                '${formatBangkokDateTime(suspendedUntil!)} '
                'เพราะคืนงานหลังเวลาฟรีบ่อยเกินไป',
    _ => 'ยังไม่ผ่านเงื่อนไขการรับงานจองล่วงหน้า',
  };

  /// "คืนงานหลังเวลาฟรี 1/3 ครั้งใน 30 วัน · ครบ 3 ครั้งจะถูกพักรับงาน";
  /// null when there is nothing to warn about.
  String? get lateReleaseLine {
    if (maxLateReleases <= 0 || lateReleases30d <= 0) return null;
    return 'คืนงานหลังเวลาฟรี $lateReleases30d/$maxLateReleases ครั้งใน 30 วัน'
        ' · ครบ $maxLateReleases ครั้งจะถูกพักรับงานจองล่วงหน้า';
  }

  /// The driver can fix it in the app (choose a vehicle type).
  bool get needsVehicleType => reasons.contains('NO_VEHICLE_TYPE');
}

/// "4.5", "4.75": no trailing zeros.
String _rating(double v) {
  final s = v.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

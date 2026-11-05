import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/utils/baht.dart';

/// Refer a driver ("ชวนเพื่อนมาขับ"): `GET /api/driver/referral`.
///
/// Every number is the backend's. A referral already running keeps the
/// rules it was created with, so its own [ReferralProgress.requiredJobs] /
/// [ReferralProgress.bonusBaht] are shown, never the top-level ones.
@immutable
class ReferralInfo {
  const ReferralInfo({
    required this.enabled,
    this.code,
    this.shareMessage = '',
    this.requiredJobs = 0,
    this.windowDays = 0,
    this.bonusBaht = 0,
    this.refereeBonusBaht = 0,
    this.summary = const ReferralSummary(),
    this.referrals = const [],
    this.referredBy,
    this.canApplyCode = false,
    this.applyBefore,
  });

  /// Off → the menu entry is hidden.
  final bool enabled;

  /// This driver's code to share; null while the program is off and no
  /// code was ever created.
  final String? code;
  final String shareMessage;
  final int requiredJobs;
  final int windowDays;
  final double bonusBaht;
  final double refereeBonusBaht;
  final ReferralSummary summary;

  /// The drivers this driver referred, newest first.
  final List<ReferralProgress> referrals;

  /// This driver's own referral, when they joined with a code.
  final ReferralProgress? referredBy;

  /// Offer the "กรอกโค้ดผู้แนะนำ" field.
  final bool canApplyCode;

  /// When the field closes; null while not approved yet (stays open).
  final DateTime? applyBefore;

  /// "เพื่อนวิ่งครบ 10 งานภายใน 30 วัน รับ ฿100", from the current rules.
  String get ruleText => referralRuleText(requiredJobs, windowDays, bonusBaht);

  /// The field is offered and not past [applyBefore].
  bool canApplyAt(DateTime now) =>
      canApplyCode && (applyBefore == null || now.isBefore(applyBefore!));

  factory ReferralInfo.fromJson(Map<String, dynamic> j) {
    final code = _str(j['code']);
    final by = j['referred_by'];
    return ReferralInfo(
      enabled: j['enabled'] == true,
      code: code,
      shareMessage: _str(j['share_message']) ?? '',
      requiredJobs: _int(j['required_jobs']),
      windowDays: _int(j['window_days']),
      bonusBaht: _num(j['bonus_baht']),
      refereeBonusBaht: _num(j['referee_bonus_baht']),
      summary: j['summary'] is Map
          ? ReferralSummary.fromJson(Map<String, dynamic>.from(j['summary']))
          : const ReferralSummary(),
      referrals: [
        for (final r in (j['referrals'] is List ? j['referrals'] as List : []))
          if (r is Map) ReferralProgress.fromJson(Map<String, dynamic>.from(r)),
      ],
      referredBy: by is Map
          ? ReferralProgress.fromJson(Map<String, dynamic>.from(by))
          : null,
      canApplyCode: j['can_apply_code'] == true,
      applyBefore: _date(j['apply_before']),
    );
  }
}

String referralRuleText(int jobs, int days, num bonus) =>
    'เพื่อนวิ่งครบ $jobs งานภายใน $days วัน รับ ${formatBaht(bonus.toDouble())}';

@immutable
class ReferralSummary {
  const ReferralSummary({
    this.invited = 0,
    this.pending = 0,
    this.completed = 0,
    this.expired = 0,
    this.earnedBaht = 0,
  });

  final int invited;
  final int pending;
  final int completed;
  final int expired;
  final double earnedBaht;

  factory ReferralSummary.fromJson(Map<String, dynamic> j) => ReferralSummary(
    invited: _int(j['invited']),
    pending: _int(j['pending']),
    completed: _int(j['completed']),
    expired: _int(j['expired']),
    earnedBaht: _num(j['earned_baht']),
  );
}

enum ReferralStatus {
  pending('กำลังวิ่ง'),
  completed('ได้รับโบนัสแล้ว'),
  expired('หมดเวลา'),
  cancelled('ยกเลิก');

  const ReferralStatus(this.label);
  final String label;

  static ReferralStatus parse(String? raw) => switch (raw?.toUpperCase()) {
    'COMPLETED' => completed,
    'EXPIRED' => expired,
    'CANCELLED' => cancelled,
    _ => pending,
  };
}

/// One referral, from either side.
@immutable
class ReferralProgress {
  const ReferralProgress({
    required this.id,
    this.name = '',
    this.code,
    this.status = ReferralStatus.pending,
    this.completedJobs = 0,
    this.requiredJobs = 0,
    this.waitingApproval = false,
    this.deadlineAt,
    this.bonusBaht = 0,
    this.paidAt,
    this.createdAt,
  });

  final String id;

  /// The referred driver, masked by the backend ("วิชัย ม."); empty on
  /// `referred_by`.
  final String name;

  /// The code used; only on `referred_by`.
  final String? code;
  final ReferralStatus status;
  final int completedJobs;
  final int requiredJobs;

  /// The referred driver isn't approved yet: the clock hasn't started and
  /// [deadlineAt] is null — show "รออนุมัติ".
  final bool waitingApproval;
  final DateTime? deadlineAt;
  final double bonusBaht;
  final DateTime? paidAt;
  final DateTime? createdAt;

  /// 0…1 for the progress bar.
  double get progress => requiredJobs <= 0
      ? 0
      : (completedJobs / requiredJobs).clamp(0, 1).toDouble();

  factory ReferralProgress.fromJson(Map<String, dynamic> j) => ReferralProgress(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    code: _str(j['code']),
    status: ReferralStatus.parse(_str(j['status'])),
    completedJobs: _int(j['completed_jobs']),
    requiredJobs: _int(j['required_jobs']),
    waitingApproval: j['waiting_approval'] == true,
    deadlineAt: _date(j['deadline_at']),
    bonusBaht: _num(j['bonus_baht']),
    paidAt: _date(j['paid_at']),
    createdAt: _date(j['created_at']),
  );
}

/// Bumped by a `driver_referral_bonus` push: the wallet and the invite
/// screen re-read. A plain notifier: the push service has no Riverpod.
class ReferralUpdates extends ChangeNotifier {
  ReferralUpdates._();
  static final ReferralUpdates instance = ReferralUpdates._();

  void notifyChanged() => notifyListeners();
}

/// The bonus was paid (`data.type = driver_referral_bonus`, with
/// `referral_id`, `role` referrer|referee, `amount` and the wallet link).
bool isDriverReferralBonusPush(Map<String, dynamic> data) =>
    data['type']?.toString() == 'driver_referral_bonus';

/// `POST /api/driver/referral/apply` refused (400 `{message, code}`).
class ReferralApplyException implements Exception {
  const ReferralApplyException(this.code, this.serverMessage);

  final String? code;
  final String? serverMessage;

  factory ReferralApplyException.from(DioException e) {
    final data = e.response?.data;
    String? read(String k) => data is Map ? _str(data[k]) : null;
    return ReferralApplyException(
      read('code'),
      read('message') ?? read('error'),
    );
  }

  /// Thai text chosen by [code]; an unknown code shows the server's words.
  String get message => switch (code) {
    'driver_referral_disabled' => 'ตอนนี้ยังไม่เปิดให้ใช้โค้ดชวนเพื่อน',
    'driver_referral_invalid_code' => 'ไม่พบโค้ดนี้ กรุณาตรวจสอบโค้ดอีกครั้ง',
    'driver_referral_self' => 'ใช้โค้ดของตัวเองไม่ได้',
    'driver_referral_mutual' => 'ใช้โค้ดของเพื่อนที่คุณชวนมาไม่ได้',
    'driver_referral_already_used' => 'คุณใส่โค้ดผู้แนะนำไปแล้ว',
    'driver_referral_window_closed' => 'หมดเวลากรอกโค้ดผู้แนะนำแล้ว',
    'driver_referral_not_driver' => 'โค้ดนี้ใช้ได้กับบัญชีคนขับเท่านั้น',
    _ => serverMessage ?? 'ใส่โค้ดไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
  };

  /// The field can't succeed any more: hide it.
  bool get closesField =>
      code == 'driver_referral_already_used' ||
      code == 'driver_referral_window_closed' ||
      code == 'driver_referral_disabled' ||
      code == 'driver_referral_not_driver';

  @override
  String toString() => 'ReferralApplyException($code)';
}

String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

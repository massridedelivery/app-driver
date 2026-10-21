import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/core/utils/thai_date.dart';

/// Quest list tabs (`GET /api/driver/quests?tab=`).
enum QuestTab {
  today('today', 'วันนี้', 'ยังไม่มีภารกิจวันนี้'),
  upcoming('upcoming', 'กำลังจะมาถึง', 'ยังไม่มีภารกิจที่กำลังจะมาถึง'),
  past('past', 'ที่ผ่านมา', 'ยังไม่มีภารกิจที่ผ่านมา');

  const QuestTab(this.api, this.label, this.empty);

  final String api;
  final String label;
  final String empty;
}

/// How a reached step's money stands (detail only).
enum QuestPayoutStatus {
  pending('รอตรวจสอบ'),
  paid('จ่ายแล้ว'),
  rejected('ไม่อนุมัติ');

  const QuestPayoutStatus(this.label);

  final String label;

  static QuestPayoutStatus? fromApi(Object? raw) =>
      switch (raw?.toString().toUpperCase()) {
        'PENDING' => pending,
        'PAID' => paid,
        'REJECTED' => rejected,
        _ => null,
      };
}

/// One step of the reward ladder. Amounts already include the driver's tier
/// multiplier (BE) — never multiplied again here.
class QuestMilestoneStep {
  const QuestMilestoneStep({
    required this.trips,
    required this.bonus,
    required this.cumulative,
    required this.reached,
    required this.tripsToGo,
    this.payoutStatus,
  });

  final int trips;
  final double bonus;

  /// Total once this step is reached ("฿750 / ฿1,500 / ฿3,000").
  final double cumulative;
  final bool reached;
  final int tripsToGo;
  final QuestPayoutStatus? payoutStatus;

  factory QuestMilestoneStep.fromJson(Map<String, dynamic> j) =>
      QuestMilestoneStep(
        trips: _int(j['trips']),
        bonus: _num(j['bonus']),
        cumulative: _num(j['cumulative']),
        reached: j['reached'] == true,
        tripsToGo: _int(j['trips_to_go']),
        payoutStatus: QuestPayoutStatus.fromApi(j['payout_status']),
      );
}

/// A quest as GET /api/driver/quests (and /quests/{id}) sends it. The backend
/// computes every figure the screens print; this only parses and formats.
class DriverQuest {
  const DriverQuest({
    required this.id,
    required this.title,
    required this.areaName,
    required this.currentCount,
    required this.targetCount,
    required this.milestones,
    required this.status,
    this.description,
    this.validFrom,
    this.validUntil,
    this.timeStart,
    this.timeEnd,
    this.endsInDays,
    this.nextMilestone,
    this.earnedAmount = 0,
    this.maxReward = 0,
    this.claimable = false,
    this.terms,
    this.questType = '',
  });

  final String id;
  final String title;
  final String? description;
  final String areaName;
  final DateTime? validFrom;
  final DateTime? validUntil;

  /// Daily window "06:00"–"10:00" (Bangkok); both null = all day.
  final String? timeStart;
  final String? timeEnd;
  final int? endsInDays;
  final int currentCount;
  final int targetCount;
  final List<QuestMilestoneStep> milestones;
  final QuestMilestoneStep? nextMilestone;
  final double earnedAmount;
  final double maxReward;

  /// NOT_STARTED, IN_PROGRESS, COMPLETED, CLAIMED, ENDED.
  final String status;

  /// Single-target quest done and waiting for POST .../claim.
  final bool claimable;
  final String? terms;

  /// COMPLETE_N_RIDES | COMPLETE_N_FOOD | COMPLETE_N_JOBS.
  final String questType;

  /// What one count is: "รอบขับ" (rides), "รอบส่งอาหาร" (food), "งาน" (all).
  String get unit => switch (questType.toUpperCase()) {
    'COMPLETE_N_FOOD' => 'รอบส่งอาหาร',
    'COMPLETE_N_JOBS' => 'งาน',
    _ => 'รอบขับ',
  };

  /// "ทำรอบขับสำเร็จ" / "ทำรอบส่งอาหารสำเร็จ" / "ทำงานสำเร็จ" before the count.
  String get countPrefix => 'ทำ$unitสำเร็จ';

  /// The count's trailing word: "รอบ" for rounds, "งาน" for jobs.
  String get countSuffix => unit == 'งาน' ? 'งาน' : 'รอบ';

  /// "รอบขับ 10 รอบ" / "10 งาน" for a ladder step.
  String stepLabel(QuestMilestoneStep s) =>
      unit == 'งาน' ? '${s.trips} งาน' : '$unit ${s.trips} รอบ';

  factory DriverQuest.fromJson(Map<String, dynamic> j) {
    final q = j['quest'] is Map
        ? Map<String, dynamic>.from(j['quest'] as Map)
        : const <String, dynamic>{};
    final tw = j['time_window'] is Map
        ? Map<String, dynamic>.from(j['time_window'] as Map)
        : null;
    final ms = (j['milestones'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => QuestMilestoneStep.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final next = j['next_milestone'] is Map
        ? QuestMilestoneStep.fromJson(
            Map<String, dynamic>.from(j['next_milestone'] as Map),
          )
        : null;
    return DriverQuest(
      id: (q['id'] ?? j['id'] ?? '').toString(),
      title: _str(j['title']) ?? _str(q['name_th']) ?? _str(q['name']) ?? '',
      description: _str(q['description']),
      areaName: _str(j['area_name']) ?? 'ทุกพื้นที่ให้บริการ',
      validFrom: _date(q['valid_from']),
      validUntil: _date(q['valid_until']),
      timeStart: _str(tw?['start']),
      timeEnd: _str(tw?['end']),
      endsInDays: j['ends_in_days'] is num
          ? (j['ends_in_days'] as num).toInt()
          : null,
      currentCount: _int(j['current_count']),
      targetCount: _int(j['target_count']),
      milestones: ms,
      nextMilestone: next,
      earnedAmount: _num(j['earned_amount']),
      maxReward: _num(j['max_reward']),
      status: (_str(j['status']) ?? '').toUpperCase(),
      claimable: j['claimable'] == true,
      terms: _str(q['terms']),
      questType: _str(q['quest_type']) ?? '',
    );
  }

  /// "19 ต.ค. - 25 ต.ค." in Bangkok time whatever the phone's zone; one day
  /// reads "21 ต.ค.".
  String get dateRange {
    final from = _bangkok(validFrom);
    final until = _bangkok(validUntil);
    String d(DateTime x) => '${x.day} ${thaiMonthsShort[x.month - 1]}';
    if (from == null && until == null) return '';
    if (from == null) return d(until!);
    if (until == null) return d(from);
    final sameDay =
        from.year == until.year &&
        from.month == until.month &&
        from.day == until.day;
    return sameDay ? d(from) : '${d(from)} - ${d(until)}';
  }

  /// "06:00-10:00", or "ทั้งวัน" without a time window.
  String get timeLabel => (timeStart == null || timeEnd == null)
      ? 'ทั้งวัน'
      : '$timeStart-$timeEnd';

  /// "สิ้นสุดวันนี้" / "สิ้นสุดใน 4 วัน"; null when the backend sent nothing.
  String? get endsLabel => switch (endsInDays) {
    null => null,
    <= 0 => 'สิ้นสุดวันนี้',
    final n => 'สิ้นสุดใน $n วัน',
  };

  /// "อีก 11 รอบ รับ ฿150", null once every step is reached.
  String? get nextLabel {
    final n = nextMilestone;
    if (n == null) return null;
    return 'อีก ${n.tripsToGo} $countSuffix รับ ${formatBaht(n.bonus)}';
  }

  /// Detail wording: "อีก 11 รอบ รับเพิ่ม ฿150".
  String? get nextExtraLabel {
    final n = nextMilestone;
    if (n == null) return null;
    return 'อีก ${n.tripsToGo} $countSuffix รับเพิ่ม ${formatBaht(n.bonus)}';
  }

  /// "ได้รับแล้วในรอบนี้ ฿100 จากสูงสุด ฿500".
  String get earnedLabel =>
      'ได้รับแล้วในรอบนี้ ${formatBaht(earnedAmount)}'
      ' จากสูงสุด ${formatBaht(maxReward)}';

  /// Progress fill 0..1 along the bar.
  double get progress =>
      targetCount <= 0 ? 0 : (currentCount / targetCount).clamp(0.0, 1.0);

  /// Where a step sits along the bar, 0..1.
  double stepAt(QuestMilestoneStep s) =>
      targetCount <= 0 ? 0 : (s.trips / targetCount).clamp(0.0, 1.0);

  List<QuestMilestoneStep> get reachedSteps =>
      milestones.where((m) => m.reached).toList();
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

/// The backend sends UTC; Thailand is UTC+7 with no daylight saving.
DateTime? _bangkok(DateTime? d) => d?.toUtc().add(const Duration(hours: 7));

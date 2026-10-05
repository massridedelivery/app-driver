// Quest / incentive models.
//
// The backend returns quests as loosely-typed JSON (`GET /api/driver/quests`),
// so parsing is deliberately tolerant: it accepts a few alternative key names
// and never throws on a missing/odd field. Shape per BE spec (PR #132):
// quest_type (e.g. COMPLETE_N_JOBS = counts every service), optional
// vehicle_types, and optional milestones:[{trips,bonus}] for stepped rewards.

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

num _asNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

String _asString(dynamic v) => v?.toString() ?? '';

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

/// Driver tier/benefits from `GET /api/driver/tier`. Shown as the header on the
/// Quests screen so it is useful even when there are no active quests.
class TierInfo {
  final String currentTier;
  final String? nextTier;
  final int jobsToNextTier;
  final int weeklyJobs;
  final num questMultiplier;
  final num baseFareBonus;

  const TierInfo({
    required this.currentTier,
    required this.nextTier,
    required this.jobsToNextTier,
    required this.weeklyJobs,
    required this.questMultiplier,
    required this.baseFareBonus,
  });

  factory TierInfo.fromJson(Map<String, dynamic> j) {
    final benefits =
        (j['benefits'] is Map) ? Map<String, dynamic>.from(j['benefits']) : const {};
    final next = j['next_tier'];
    return TierInfo(
      currentTier: _asString(j['current_tier'] ?? j['tier']),
      nextTier: (next == null || next.toString().isEmpty) ? null : _asString(next),
      jobsToNextTier: _asInt(j['jobs_to_next_tier']),
      weeklyJobs: _asInt(j['weekly_jobs'] ?? j['weekly_completed_jobs']),
      questMultiplier: _asNum(benefits['quest_multiplier'] ?? 1),
      baseFareBonus: _asNum(benefits['base_fare_bonus']),
    );
  }
}

/// A single stepped reward within a quest: hit [trips] completed jobs, earn
/// [bonus]. The bonus is queued for admin approval, not paid instantly.
class QuestMilestone {
  final int trips;
  final num bonus;

  const QuestMilestone({required this.trips, required this.bonus});

  factory QuestMilestone.fromJson(Map<String, dynamic> j) => QuestMilestone(
        trips: _asInt(j['trips'] ?? j['target'] ?? j['count'] ?? j['goal']),
        bonus: _asNum(j['bonus'] ?? j['reward'] ?? j['amount']),
      );
}

class Quest {
  final String id;
  final String title;
  final String description;

  /// Raw backend quest type, e.g. `COMPLETE_N_JOBS`.
  final String questType;

  /// Vehicle types this quest is limited to (empty = all vehicles).
  final List<String> vehicleTypes;

  /// Jobs completed so far toward the quest.
  final int progress;

  /// Target for a single-target quest (0 when the quest is milestone-based).
  final int target;

  /// Reward for a single-target quest (0 when milestone-based).
  final num bonus;

  /// Stepped rewards; empty for a single-target quest.
  final List<QuestMilestone> milestones;

  /// Raw status, e.g. ACTIVE / COMPLETED / CLAIMED / PENDING_REVIEW.
  final String status;

  /// Whether the "claim reward" action is currently available.
  final bool claimable;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.questType,
    required this.vehicleTypes,
    required this.progress,
    required this.target,
    required this.bonus,
    required this.milestones,
    required this.status,
    required this.claimable,
  });

  factory Quest.fromJson(Map<String, dynamic> j) {
    final milestonesRaw = j['milestones'];
    final milestones = (milestonesRaw is List)
        ? milestonesRaw
            .whereType<Map>()
            .map((m) => QuestMilestone.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <QuestMilestone>[];

    return Quest(
      id: _asString(j['id'] ?? j['quest_id'] ?? j['_id']),
      title: _asString(j['title'] ?? j['name']),
      description: _asString(j['description'] ?? j['desc'] ?? j['subtitle']),
      questType: _asString(j['quest_type'] ?? j['type']),
      vehicleTypes: _asStringList(j['vehicle_types'] ?? j['vehicleTypes']),
      progress: _asInt(j['progress'] ?? j['current'] ?? j['completed_jobs']),
      target: _asInt(j['target'] ?? j['goal'] ?? j['required']),
      bonus: _asNum(j['bonus'] ?? j['reward'] ?? j['amount']),
      milestones: milestones,
      status: _asString(j['status']).toUpperCase(),
      claimable: j['claimable'] == true || j['can_claim'] == true,
    );
  }

  bool get hasMilestones => milestones.isNotEmpty;

  /// COMPLETE_N_JOBS counts every service (ride + food + messenger) together.
  bool get isAllServices => questType.toUpperCase() == 'COMPLETE_N_JOBS';

  /// Short label for the service scope, or null to hide the chip.
  String? get serviceLabel => isAllServices ? 'ทุกบริการ' : null;

  /// A reward claimed on this quest sits in admin review before it hits the
  /// wallet — the UI must say "รอตรวจสอบ", never "เข้ากระเป๋าแล้ว".
  bool get isPendingReview =>
      status == 'PENDING_REVIEW' ||
      status == 'PENDING' ||
      status == 'UNDER_REVIEW' ||
      status == 'CLAIMED';

  bool get isCompleted => status == 'COMPLETED' || status == 'DONE';

  /// The highest target to show progress against: the last milestone's trips,
  /// else the single [target].
  int get maxTarget =>
      hasMilestones ? milestones.map((m) => m.trips).fold(0, (a, b) => a > b ? a : b) : target;
}

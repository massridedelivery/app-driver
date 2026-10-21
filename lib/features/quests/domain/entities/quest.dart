// Driver tier (`GET /api/driver/tier`). Quests themselves are DriverQuest
// (driver_quest.dart). Parsing is tolerant: alternative key names, never
// throws on a missing/odd field.

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
    final benefits = (j['benefits'] is Map)
        ? Map<String, dynamic>.from(j['benefits'])
        : const {};
    final next = j['next_tier'];
    return TierInfo(
      currentTier: _asString(j['current_tier'] ?? j['tier']),
      nextTier: (next == null || next.toString().isEmpty)
          ? null
          : _asString(next),
      jobsToNextTier: _asInt(j['jobs_to_next_tier']),
      weeklyJobs: _asInt(j['weekly_jobs'] ?? j['weekly_completed_jobs']),
      questMultiplier: _asNum(benefits['quest_multiplier'] ?? 1),
      baseFareBonus: _asNum(benefits['base_fare_bonus']),
    );
  }
}

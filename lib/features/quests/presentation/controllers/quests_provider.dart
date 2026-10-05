import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/quests/domain/entities/quest.dart';

/// Active driver quests (`GET /api/driver/quests`), parsed into [Quest].
/// autoDispose so each visit to the Quests screen fetches fresh progress.
final questsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final res = await getIt<QuestApiService>().getQuests();
  // The endpoint returns `null` (not []) when the driver has no active quests.
  final raw = res.data ?? const <dynamic>[];
  return raw
      .whereType<Map>()
      .map((m) => Quest.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

/// Driver tier/benefits (`GET /api/driver/tier`) for the Quests screen header.
/// Returns null on any failure so the header simply hides.
final tierProvider = FutureProvider.autoDispose<TierInfo?>((ref) async {
  try {
    final res = await getIt<QuestApiService>().getTier();
    final data = res.data;
    if (data == null) return null;
    return TierInfo.fromJson(Map<String, dynamic>.from(data));
  } catch (_) {
    return null;
  }
});

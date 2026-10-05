import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/quests/domain/entities/quest.dart';

/// Active driver quests (`GET /api/driver/quests`), parsed into [Quest].
/// autoDispose so each visit to the Quests screen fetches fresh progress.
final questsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final res = await getIt<QuestApiService>().getQuests();
  final raw = res.data ?? const <dynamic>[];
  return raw
      .whereType<Map>()
      .map((m) => Quest.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

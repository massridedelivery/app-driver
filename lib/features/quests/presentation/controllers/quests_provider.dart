import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/quests/domain/entities/driver_quest.dart';
import 'package:massdrive/features/quests/domain/entities/quest.dart';

/// One tab of the driver's quests (`GET /api/driver/quests?tab=`). autoDispose
/// so every visit fetches fresh progress.
final questsTabProvider = FutureProvider.autoDispose
    .family<List<DriverQuest>, QuestTab>((ref, tab) async {
      final res = await getIt<QuestApiService>().getQuests(tab: tab.api);
      // The endpoint can return `null` (not []) when there is nothing.
      final raw = res.data ?? const <dynamic>[];
      return raw
          .whereType<Map>()
          .map((m) => DriverQuest.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    });

/// Thrown when a quest no longer exists (404): the detail goes back.
class QuestGoneException implements Exception {
  const QuestGoneException();
}

/// One quest's detail (`GET /api/driver/quests/{id}`).
final questDetailProvider = FutureProvider.autoDispose
    .family<DriverQuest, String>((ref, id) async {
      try {
        final res = await getIt<QuestApiService>().getQuest(id);
        return DriverQuest.fromJson(res.data ?? const {});
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) throw const QuestGoneException();
        rethrow;
      }
    });

/// Driver tier/benefits (`GET /api/driver/tier`). Null on any failure so the
/// tier label simply hides.
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

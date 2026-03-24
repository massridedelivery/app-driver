import 'package:injectable/injectable.dart';
import '../../data/sources/quest_api_service.dart';
import '../../domain/repositories/quest_repository.dart';

@LazySingleton(as: QuestRepository)
class QuestRepositoryImpl implements QuestRepository {
  final QuestApiService _apiService;

  QuestRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getTier() async {
    final response = await _apiService.getTier();
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> getQuests() async {
    final response = await _apiService.getQuests();
    return response.data ?? [];
  }

  @override
  Future<Map<String, dynamic>> claimQuest(String questId) async {
    final response = await _apiService.claimQuest(questId);
    return response.data ?? {};
  }
}

abstract class QuestRepository {
  Future<Map<String, dynamic>> getTier();
  Future<List<dynamic>> getQuests();
  Future<Map<String, dynamic>> claimQuest(String questId);
}

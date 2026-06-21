import '../models/history_item_model.dart';

abstract class HistoryListRepository {
  Future<List<HistoryItemModel>> getHistoryList({
    required int page,
    required int limit,
  });
}

import '../models/history_item_model.dart';

abstract class HistoryListRepository {
  Future<List<HistoryItemModel>> getHistoryList({
    required int limit,
    required int offset,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  });
}

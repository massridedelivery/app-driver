import '../models/history_item_api_model.dart';

abstract class HistoryListApiService {
  Future<HistoryListResponseModel> getHistoryList({
    required int limit,
    required int offset,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  });
}

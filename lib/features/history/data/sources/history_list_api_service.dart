import '../models/history_item_api_model.dart';

abstract class HistoryListApiService {
  Future<HistoryListResponseModel> getHistoryList({
    required int page,
    required int limit,
  });
}

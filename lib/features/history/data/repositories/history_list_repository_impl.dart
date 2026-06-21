import 'package:injectable/injectable.dart';
import '../../domain/models/history_item_model.dart';
import '../../domain/repositories/history_list_repository.dart';
import '../sources/history_list_api_service.dart';

@LazySingleton(as: HistoryListRepository)
class HistoryListRepositoryImpl implements HistoryListRepository {
  final HistoryListApiService _apiService;

  HistoryListRepositoryImpl(this._apiService);

  @override
  Future<List<HistoryItemModel>> getHistoryList({
    required int page,
    required int limit,
  }) async {
    final response = await _apiService.getHistoryList(page: page, limit: limit);
    return response.data.map((model) => model.toEntity()).toList();
  }
}

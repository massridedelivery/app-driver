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
    required int limit,
    required int offset,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _apiService.getHistoryList(
      limit: limit,
      offset: offset,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
    return response.data.map((model) => model.toEntity()).toList();
  }
}

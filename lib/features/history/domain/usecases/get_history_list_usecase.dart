import 'package:injectable/injectable.dart';
import '../models/history_item_model.dart';
import '../repositories/history_list_repository.dart';

@injectable
class GetHistoryListUseCase {
  final HistoryListRepository _repository;

  GetHistoryListUseCase(this._repository);

  Future<List<HistoryItemModel>> execute({
    int limit = 20,
    int offset = 0,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) {
    return _repository.getHistoryList(
      limit: limit,
      offset: offset,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

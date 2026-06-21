import 'package:injectable/injectable.dart';
import '../models/history_item_model.dart';
import '../repositories/history_list_repository.dart';

@injectable
class GetHistoryListUseCase {
  final HistoryListRepository _repository;

  GetHistoryListUseCase(this._repository);

  Future<List<HistoryItemModel>> execute({
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getHistoryList(page: page, limit: limit);
  }
}

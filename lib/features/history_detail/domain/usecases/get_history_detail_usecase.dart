import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';
import 'package:massdrive/features/history_detail/domain/repositories/history_repository.dart';

class GetHistoryDetailUseCase {
  final HistoryRepository repository;

  GetHistoryDetailUseCase(this.repository);

  Future<HistoryDetailEntity> call(String id) {
    return repository.getHistoryDetail(id);
  }
}

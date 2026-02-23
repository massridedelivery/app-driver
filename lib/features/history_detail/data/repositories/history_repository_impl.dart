import 'package:massdrive/features/history_detail/data/datasource/history_remote_datasource.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';
import 'package:massdrive/features/history_detail/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDatasource remote;

  HistoryRepositoryImpl(this.remote);

  @override
  Future<HistoryDetailEntity> getHistoryDetail(String id) async {
    final model = await remote.getHistoryDetail(id);
    return model.toEntity();
  }
}

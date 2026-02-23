import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

abstract class HistoryRepository {
  Future<HistoryDetailEntity> getHistoryDetail(String id);
}

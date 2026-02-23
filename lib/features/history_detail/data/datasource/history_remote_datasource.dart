import 'package:dio/dio.dart';
import 'package:massdrive/features/history_detail/data/models/history_model.dart';

abstract class HistoryRemoteDatasource {
  Future<HistoryModel> getHistoryDetail(String id);
}

class HistoryRemoteDatasourceImpl implements HistoryRemoteDatasource {
  final Dio dio;

  HistoryRemoteDatasourceImpl(this.dio);

  @override
  Future<HistoryModel> getHistoryDetail(String id) async {
    final response = await dio.get('/history/$id');
    return HistoryModel.fromJson(response.data);
  }
}

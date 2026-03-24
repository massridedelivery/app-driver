import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class QuestApiService {
  Future<Response<Map<String, dynamic>>> getTier();
  Future<Response<List<dynamic>>> getQuests();
  Future<Response<Map<String, dynamic>>> claimQuest(String questId);
}

@LazySingleton(as: QuestApiService)
class QuestApiServiceImpl implements QuestApiService {
  final Dio _dio;

  QuestApiServiceImpl(this._dio);

  @override
  Future<Response<Map<String, dynamic>>> getTier() async {
    return await _dio.get<Map<String, dynamic>>(Endpoints.driverTier);
  }

  @override
  Future<Response<List<dynamic>>> getQuests() async {
    return await _dio.get<List<dynamic>>(Endpoints.driverQuests);
  }

  @override
  Future<Response<Map<String, dynamic>>> claimQuest(String questId) async {
    final endpoint = Endpoints.driverQuestsClaim.replaceAll(':id', questId);
    return await _dio.post<Map<String, dynamic>>(endpoint);
  }
}

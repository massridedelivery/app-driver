import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class QuestApiService {
  Future<Response<Map<String, dynamic>>> getTier();
  /// [tab]: today (default) | upcoming | past.
  Future<Response<List<dynamic>>> getQuests({String? tab});

  /// One quest with payout_status on reached steps; 404 = gone.
  Future<Response<Map<String, dynamic>>> getQuest(String questId);
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
  Future<Response<List<dynamic>>> getQuests({String? tab}) async {
    return await _dio.get<List<dynamic>>(
      Endpoints.driverQuests,
      queryParameters: {if (tab != null) 'tab': tab},
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> getQuest(String questId) async {
    return await _dio.get<Map<String, dynamic>>(
      '${Endpoints.driverQuests}/$questId',
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> claimQuest(String questId) async {
    final endpoint = Endpoints.driverQuestsClaim.replaceAll(':id', questId);
    return await _dio.post<Map<String, dynamic>>(endpoint);
  }
}

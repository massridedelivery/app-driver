import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import '../models/history_item_api_model.dart';
import 'history_list_api_service.dart';

@LazySingleton(as: HistoryListApiService)
class HistoryListApiServiceImpl implements HistoryListApiService {
  final Dio _dio;

  HistoryListApiServiceImpl(this._dio);

  @override
  Future<HistoryListResponseModel> getHistoryList({
    required int limit,
    required int offset,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final response = await _dio.get(
        Endpoints.driverEarningsTransactions,
        queryParameters: queryParams,
      );
      return HistoryListResponseModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e, st) {
      debugPrint('HistoryListApiServiceImpl ERROR: $e');
      debugPrint('STACKTRACE: $st');
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['error'] != null) {
          throw Exception(e.response?.data['error']);
        }
      }
      rethrow; // let controller see the real error instead of hiding in mock
    }
  }
}

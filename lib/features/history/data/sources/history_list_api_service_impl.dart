import 'package:dio/dio.dart';
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
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _dio.get(
        Endpoints.driverEarningsTrips,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      return HistoryListResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      return _mockResponse(page, limit);
    }
  }

  HistoryListResponseModel _mockResponse(int page, int limit) {
    final now = DateTime.now();
    final items = [
      HistoryItemApiModel(
        jobId: "1",
        completedAt: DateTime(now.year, now.month, now.day, 21, 57).toUtc().toIso8601String(),
        earnings: 28.0,
        distanceKm: 2.1,
        paymentMethod: "GRAB_PAY",
        type: "RIDE",
        title: "เกษรอัมรินทร์ ทางเข้าล็อบบี้ออฟฟิศ",
        status: "COMPLETED",
      ),
      HistoryItemApiModel(
        jobId: "2",
        completedAt: DateTime(now.year, now.month, now.day, 21, 27).toUtc().toIso8601String(),
        earnings: 45.0,
        distanceKm: 3.5,
        paymentMethod: "CASH",
        type: "FOOD",
        title: "ร้านขนมหวานสุดอร่อย → Condo",
        status: "COMPLETED",
      ),
      HistoryItemApiModel(
        jobId: "3",
        completedAt: DateTime(now.year, now.month, now.day, 20, 57).toUtc().toIso8601String(),
        earnings: null,
        distanceKm: 0.0,
        paymentMethod: null,
        type: "FOOD",
        title: "ก๋วยเตี๋ยวต้มยำสามล้อสูตรโบราณ",
        status: "CANCELLED",
      ),
      HistoryItemApiModel(
        jobId: "4",
        completedAt: DateTime(now.year, now.month, now.day, 19, 57).toUtc().toIso8601String(),
        earnings: 65.0,
        distanceKm: 5.0,
        paymentMethod: "GRAB_PAY",
        type: "RIDE",
        title: "อนุสาวรีย์ชัย → สีลม",
        status: "COMPLETED",
      ),
    ];

    return HistoryListResponseModel(
      data: items,
      page: page,
      limit: limit,
      total: items.length,
    );
  }
}

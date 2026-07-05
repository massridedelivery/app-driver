import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/wallet/data/sources/wallet_overview_api_service.dart';

@LazySingleton(as: WalletOverviewApiService)
class WalletOverviewApiServiceImpl implements WalletOverviewApiService {
  final Dio _dio;

  WalletOverviewApiServiceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getWalletOverview({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        Endpoints.driverEarnings,
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      // Mock fallback – matches the real GET /api/driver/earnings shape (§1).
      // When a date range is given, today_earnings is the period total.
      final isPeriod = startDate != null || endDate != null;
      return {
        'balance': -350.00,
        'withdrawn': 500.00,
        'today_earnings': isPeriod ? 2450.00 : 450.00,
        'total_trips': isPeriod ? 28 : 8,
        'is_verified': true,
      };
    }
  }
}

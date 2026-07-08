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
      // Mock fallback – matches the typed EarningsSummary shapes (v1.6.0-dev16).
      const common = {
        'balance': -350.00,
        'available_balance': 447.76,
        'withdrawn': 500.00,
        'is_verified': true,
      };
      if (startDate != null && endDate != null) {
        // Ranged (single window) shape.
        return {
          ...common,
          'earnings': 1830.00,
          'total_trips': 12,
          'range': {'start_date': startDate, 'end_date': endDate},
        };
      }
      // No-range (rolling breakdown) shape.
      return {
        ...common,
        'today_earnings': 450.00,
        'this_week_earnings': 2450.00,
        'this_month_earnings': 8600.00,
        'this_year_earnings': 84000.00,
        'total_trips': 8,
      };
    }
  }
}

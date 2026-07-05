import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/wallet/data/sources/wallet_overview_api_service.dart';

@LazySingleton(as: WalletOverviewApiService)
class WalletOverviewApiServiceImpl implements WalletOverviewApiService {
  final Dio _dio;

  WalletOverviewApiServiceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getWalletOverview() async {
    try {
      final response = await _dio.get(Endpoints.driverEarnings);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      // Mock fallback – matches the real GET /api/driver/earnings shape (§1).
      return {
        'balance': -350.00,
        'withdrawn': 500.00,
        'today_earnings': 450.00,
        'total_trips': 8,
        'is_verified': true,
      };
    }
  }
}

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
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
      // Never substitute a made-up balance: this feeds the earnings headline
      // and a driver cannot tell a fabricated figure from a real one.
      ApiError.surface(e, 'Failed to fetch wallet overview');
    }
  }
}

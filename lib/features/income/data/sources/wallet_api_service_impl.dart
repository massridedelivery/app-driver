import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';

/// Wallet, payout and settlement calls.
///
/// Every failure surfaces. These endpoints carry money — a canned balance, a
/// fake QR or an invented "PAID" is indistinguishable from the real thing to
/// the driver looking at it, so nothing here substitutes a stand-in response.
@LazySingleton(as: WalletApiService)
class WalletApiServiceImpl implements WalletApiService {
  final Dio _dio;

  WalletApiServiceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getPayouts() async {
    try {
      final response = await _dio.get(Endpoints.driverPayouts);
      if (response.data is List) return {'data': response.data};
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to fetch payouts');
    }
  }

  @override
  Future<Map<String, dynamic>> getPayoutSummary() async {
    try {
      final response = await _dio.get(Endpoints.driverPayoutsSummary);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to fetch payout summary');
    }
  }

  @override
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverPayouts, data: data);
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to request payout');
    }
  }

  @override
  Future<Map<String, dynamic>> settleDebt(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverSettleDebt, data: data);
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to settle debt');
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentIntent(String intentId) async {
    try {
      final response = await _dio.get(Endpoints.paymentIntent(intentId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to fetch payment intent');
    }
  }

  @override
  Future<Map<String, dynamic>> submitSettlementSlip(
    String intentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Endpoints.driverSettleDebtSlip(intentId);
      final response = await _dio.post(url, data: data);
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to submit settlement slip');
    }
  }

  @override
  Future<Map<String, dynamic>> getCodStatus() async {
    try {
      final response = await _dio.get(Endpoints.driverCodStatus);
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to fetch COD status');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactions({String? type}) async {
    try {
      final response = await _dio.get(
        Endpoints.driverEarningsTransactions,
        queryParameters: type != null ? {'type': type} : null,
      );
      if (response.data is List) return {'data': response.data};
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to fetch transactions');
    }
  }

  @override
  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final response = await _dio.get(Endpoints.driverEarnings);
      return response.data;
    } on DioException catch (e) {
      ApiError.surface(e, 'Failed to fetch earnings');
    }
  }
}

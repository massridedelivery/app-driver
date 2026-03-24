import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';

@LazySingleton(as: WalletApiService)
class WalletApiServiceImpl implements WalletApiService {
  final Dio _dio;

  WalletApiServiceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getWalletType() async {
    try {
      final response = await _dio.get(Endpoints.walletType);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to fetch wallet type');
    }
  }

  @override
  Future<Map<String, dynamic>> getPayouts() async {
    try {
      final response = await _dio.get(Endpoints.driverPayouts);
      if (response.data is List) return {'data': response.data};
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to fetch payouts');
    }
  }

  @override
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverPayouts, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to request payout');
    }
  }

  @override
  Future<Map<String, dynamic>> topup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverTopup, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to topup');
    }
  }

  @override
  Future<Map<String, dynamic>> getCodStatus() async {
    try {
      final response = await _dio.get(Endpoints.driverCodStatus);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to fetch COD status');
    }
  }
}

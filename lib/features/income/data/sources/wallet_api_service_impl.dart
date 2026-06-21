import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';

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
  Future<Map<String, dynamic>> submitTopupSlip(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverTopupSlip, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to submit top-up slip');
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

  @override
  Future<Map<String, dynamic>> getTransactions({String? type}) async {
    try {
      final response = await _dio.get(
        Endpoints.driverEarningsTransactions,
        queryParameters: type != null ? {'type': type} : null,
      );
      if (response.data is List) return {'data': response.data};
      return response.data;
    } on DioException {
      // Mock fallback – return sample transactions while backend isn't ready
      return {
        'transactions': [
          {
            'id': 'txn-001',
            'type': type ?? 'payout',
            'amount': 500.0,
            'status': 'completed',
            'description': 'โอนเงินไปยังบัญชี',
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
          {
            'id': 'txn-002',
            'type': type ?? 'topup',
            'amount': 200.0,
            'status': 'completed',
            'description': 'เติมเงินเครดิต',
            'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          },
          {
            'id': 'txn-003',
            'type': type ?? 'earning',
            'amount': 85.0,
            'status': 'completed',
            'description': 'รายได้จากงาน #A-8P8KEI5',
            'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          },
        ],
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final response = await _dio.get(Endpoints.driverEarnings);
      return response.data;
    } on DioException {
      // Mock fallback – return sample earnings while backend isn't ready
      return {
        'today': 350.0,
        'this_week': 2450.0,
        'total_trips_today': 4,
        'total_trips_week': 28,
      };
    }
  }
}


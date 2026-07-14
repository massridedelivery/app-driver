import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/wallet/data/sources/transaction_api_service.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';

@LazySingleton(as: TransactionApiService)
class TransactionApiServiceImpl implements TransactionApiService {
  final Dio _dio;

  TransactionApiServiceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getTransactions(TransactionQuery query) async {
    try {
      final response = await _dio.get(
        Endpoints.driverEarningsTransactions,
        queryParameters: query.toQueryParameters(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      // Mock fallback – return sample transactions while backend isn't ready
      return _mockResponse(query);
    }
  }

  Map<String, dynamic> _mockResponse(TransactionQuery query) {
    final now = DateTime.now().toUtc();
    return {
      'transactions': [
        {
          'id': 'tx_001',
          'type': 'FARE_PAYMENT',
          'amount': 180.00,
          'status': 'COMPLETED',
          'description': 'Trip #JOB-9981',
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'tx_002',
          'type': 'COMMISSION_DEDUCTION',
          'amount': -36.00,
          'status': 'COMPLETED',
          'description': 'Commission for #JOB-9981',
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'tx_003',
          'type': 'FARE_PAYMENT',
          'amount': 120.00,
          'status': 'COMPLETED',
          'description': 'Trip #JOB-9975',
          'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 'tx_004',
          'type': 'COMMISSION_DEDUCTION',
          'amount': -24.00,
          'status': 'COMPLETED',
          'description': 'Commission for #JOB-9975',
          'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 'tx_005',
          'type': 'BONUS',
          'amount': 50.00,
          'status': 'COMPLETED',
          'description': 'Quest reward – 5 trips bonus',
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 'tx_006',
          'type': 'TOPUP',
          'amount': 200.00,
          'status': 'PENDING',
          'description': 'เติมเงินผ่าน bank slip',
          'created_at': now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
        },
        {
          'id': 'tx_007',
          'type': 'WITHDRAWAL',
          'amount': -500.00,
          'status': 'COMPLETED',
          'description': 'โอนไปยังบัญชี KBank',
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
      ],
      'total': 142,
    };
  }
}

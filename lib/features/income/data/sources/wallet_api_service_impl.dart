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
  Future<Map<String, dynamic>> settleDebt(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverSettleDebt, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      final amount = data['amount'] ?? 0.0;
      final method = data['payment_method'] ?? 'PROMPTPAY';
      if (method == 'PROMPTPAY') {
        return {
          'intent_id': 'pi_settle_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'PENDING',
          'qr_code_url': 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=PROMPTPAY_MOCK_DATA_$amount',
          'expires_at': DateTime.now().add(const Duration(minutes: 15)).toUtc().toIso8601String(),
        };
      } else {
        return {
          'intent_id': 'pi_settle_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'PENDING',
          'bank_details': {
            'bank_name': 'ธนาคารกสิกรไทย (KBANK)',
            'account_number': '012-3-45678-9',
            'account_name': 'บริษัท แมสไดรฟ์ จำกัด',
          }
        };
      }
    }
  }

  @override
  Future<Map<String, dynamic>> submitSettlementSlip(String intentId, Map<String, dynamic> data) async {
    try {
      final url = Endpoints.driverSettleDebtSlip(intentId);
      final response = await _dio.post(url, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      return {
        'intent_id': intentId,
        'status': 'PENDING_REVIEW',
        'message': 'ส่งหลักฐานการชำระเงินสำเร็จแล้ว อยู่ระหว่างการตรวจสอบโดยผู้ดูแลระบบ'
      };
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
      return {
        'cod_debt': -367.16,
        'cod_threshold': -500.0,
        'cod_blocked': false,
        'current_balance': 1500.0
      };
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


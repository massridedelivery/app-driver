import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';

@LazySingleton(as: WalletApiService)
class WalletApiServiceImpl implements WalletApiService {
  final Dio _dio;

  WalletApiServiceImpl(this._dio);

  /// Whether canned/mock responses may stand in for an unreachable backend.
  /// Debug builds only — release must never fabricate wallet/payment data.
  static bool get _allowMockFallback => kDebugMode;

  /// A business/validation failure the driver must see — NEVER masked by a
  /// mock, even in debug. Covers the SCRUM-35 §6 security-critical cases:
  /// 400 (bad/underpaid amount, unsupported method), 401 (auth), 403 (foreign
  /// job/intent), 409 (already paid). 404 (endpoint not yet wired in dev) and
  /// 5xx/network are allowed to fall through to the dev mock.
  static bool _mustSurface(DioException e) {
    final code = e.response?.statusCode;
    return code == 400 || code == 401 || code == 403 || code == 409;
  }

  /// Human-readable reason from the backend, preferring the contract's
  /// `message` field (SCRUM-35 §6), falling back to legacy `error`.
  static String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'])?.toString();
    }
    return null;
  }

  /// Rethrow the error with the best message available. Call this whenever a
  /// mock is not appropriate (business error, or release build).
  static Never _surface(DioException e, String fallbackMessage) {
    throw Exception(_serverMessage(e) ?? fallbackMessage);
  }

  @override
  Future<Map<String, dynamic>> getPayouts() async {
    try {
      final response = await _dio.get(Endpoints.driverPayouts);
      if (response.data is List) return {'data': response.data};
      return response.data;
    } on DioException catch (e) {
      _surface(e, 'Failed to fetch payouts');
    }
  }

  @override
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverPayouts, data: data);
      return response.data;
    } on DioException catch (e) {
      _surface(e, 'Failed to request payout');
    }
  }

  @override
  Future<Map<String, dynamic>> settleDebt(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.driverSettleDebt, data: data);
      return response.data;
    } on DioException catch (e) {
      // A rejected settlement (bad amount, blocked, already paid…) must surface
      // — never fake a QR on top of a real 4xx.
      if (_mustSurface(e) || !_allowMockFallback) {
        _surface(e, 'Failed to settle debt');
      }
      // Dev-only fallback while the PromptPay/Omise gateway is WIP-gated.
      final amount = data['amount'] ?? 0.0;
      final method = data['payment_method'] ?? 'PROMPTPAY';
      if (method == 'PROMPTPAY') {
        return {
          'intent_id': 'pi_settle_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'AWAITING_PAYMENT',
          'qr_code_url': 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=PROMPTPAY_MOCK_DATA_$amount',
          'expires_at': DateTime.now().add(const Duration(minutes: 15)).toUtc().toIso8601String(),
        };
      } else {
        return {
          'intent_id': 'pi_settle_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'AWAITING_PAYMENT',
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
  Future<Map<String, dynamic>> getPaymentIntent(String intentId) async {
    try {
      final response = await _dio.get(Endpoints.paymentIntent(intentId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // A real intent lookup that 4xx's (not found / forbidden) must surface.
      if (_mustSurface(e) || !_allowMockFallback) {
        _surface(e, 'Failed to fetch payment intent');
      }
      // Dev-only fallback: mock intents are minted as `pi_settle_<createdMs>`
      // in [settleDebt]; simulate the gateway confirming payment ~10s after
      // creation so the polling flow is exercisable without a live backend.
      final createdMs = int.tryParse(intentId.split('_').last);
      if (createdMs != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - createdMs;
        return {
          'id': intentId,
          'status': elapsed > 10000 ? 'PAID' : 'AWAITING_PAYMENT',
          if (elapsed > 10000)
            'paid_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
      _surface(e, 'Failed to fetch payment intent');
    }
  }

  @override
  Future<Map<String, dynamic>> submitSettlementSlip(String intentId, Map<String, dynamic> data) async {
    try {
      final url = Endpoints.driverSettleDebtSlip(intentId);
      final response = await _dio.post(url, data: data);
      return response.data;
    } on DioException catch (e) {
      if (_mustSurface(e) || !_allowMockFallback) {
        _surface(e, 'Failed to submit settlement slip');
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
      if (_mustSurface(e) || !_allowMockFallback) {
        _surface(e, 'Failed to fetch COD status');
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
    } on DioException catch (e) {
      if (_mustSurface(e) || !_allowMockFallback) {
        _surface(e, 'Failed to fetch transactions');
      }
      // Dev-only mock while backend isn't ready.
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
    } on DioException catch (e) {
      if (_mustSurface(e) || !_allowMockFallback) {
        _surface(e, 'Failed to fetch earnings');
      }
      // Dev-only mock while backend isn't ready.
      return {
        'today': 350.0,
        'this_week': 2450.0,
        'total_trips_today': 4,
        'total_trips_week': 28,
      };
    }
  }
}

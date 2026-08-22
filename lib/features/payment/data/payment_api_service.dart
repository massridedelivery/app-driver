import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/managers/api/api_manager.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_api_service.g.dart';

/// End-of-job payment collection on the driver app (SCRUM-86).
class PaymentApiService {
  final Dio _dio;

  PaymentApiService({required Dio dio}) : _dio = dio;

  /// Mint (or reuse) a QR payment intent for the payer to scan.
  /// Idempotent server-side: a still-live QR comes back with `reused=true` —
  /// the driver can tap "เก็บเงิน" repeatedly without double-charging.
  /// Response: { intent_id, status, amount, qr_code_url, expires_at, reused }.
  Future<ResponseData> createIntent({
    required String orderId,
    required bool messenger,
  }) async {
    final path = (messenger
            ? Endpoints.messengerOrderPaymentIntent
            : Endpoints.driverJobPaymentIntent)
        .replaceAll(':id', orderId);
    final res = await _dio.post(path);
    return _wrap(res);
  }

  /// Poll a payment intent's status — the fallback to the `payment_paid` WS
  /// event. Response: { status, amount, ... }.
  Future<ResponseData> getIntent(String intentId) async {
    final res = await _dio.get(Endpoints.paymentIntent(intentId));
    return _wrap(res);
  }

  /// Confirm cash received from the payer (messenger only) → triggers
  /// settlement. No amount is sent — the server reads it from the order.
  /// Response: the updated order (payment_status=PAID, amount_due=0).
  Future<ResponseData> collectCash({required String orderId}) async {
    final res = await _dio.post(
      Endpoints.messengerOrderCollectCash.replaceAll(':id', orderId),
    );
    return _wrap(res);
  }

  ResponseData _wrap(Response res) => ResponseData(
        data: res.data,
        isSuccessful: res.statusCode == 200 || res.statusCode == 201,
        errorStatusCode: res.statusCode ?? 0,
      );
}

@riverpod
PaymentApiService paymentApiService(Ref ref) {
  return PaymentApiService(dio: getIt<Dio>());
}

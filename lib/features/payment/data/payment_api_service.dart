import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/managers/api/api_manager.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/income/domain/models/held_fare.dart';
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

  /// A ride's toll as its total (BE: 1–500). Throws on a refusal, e.g. 409
  /// once the passenger has paid; the body's message says why.
  Future<void> setRideToll({required String jobId, required double toll}) =>
      _dio.put(
        Endpoints.driverJobToll.replaceAll(':id', jobId),
        data: {'toll_fee': toll},
      );

  /// A ride's other cost (parking, a gate) as its total, with what it was;
  /// 0 clears it.
  Future<void> setRideOtherFee({
    required String jobId,
    required double fee,
    required String note,
  }) => _dio.put(
    Endpoints.driverJobOtherFee.replaceAll(':id', jobId),
    data: {'other_fee': fee, 'note': note},
  );

  /// A parcel's other cost as its total, with what it was; 0 clears it.
  /// Returns the updated order.
  Future<Map<String, dynamic>> setParcelOtherFee({
    required String orderId,
    required double fee,
    required String note,
  }) async {
    final res = await _dio.put(
      Endpoints.messengerOrderOtherFee.replaceAll(':id', orderId),
      data: {'other_fee': fee, 'note': note},
    );
    final data = res.data;
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  /// Held fares — override-claimed fares awaiting finance review (dev15).
  /// GET /api/driver/payments/held → { items: [...], total }.
  Future<List<HeldFare>> getHeldFares() async {
    final res = await _dio.get(Endpoints.driverPaymentsHeld);
    final data = res.data;
    final items = (data is Map ? data['items'] : null) as List? ?? const [];
    return items
        .whereType<Map>()
        .map((e) => HeldFare.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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

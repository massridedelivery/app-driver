import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';

/// How accepting a next-ride offer ended.
enum NextRideAcceptOutcome {
  /// 200 `{"message":"job queued","queued":true}` (a repeat answers the same).
  queued,

  /// 409 `next_ride_unavailable`: the trip it was offered against is over, or
  /// another ride is already queued. Close the card without a word.
  unavailable,

  /// 409 `job_taken` / `job_cancelled`, 403 `job_not_offered`: gone.
  gone,

  /// 403 `CASH_JOBS_BLOCKED`: a cash ride below the cash-job floor.
  cashBlocked,

  /// 200 without `queued`: not a next-ride accept after all.
  notQueued,

  /// Network / server error: the driver may try again.
  failed,
}

/// The `code` of an error body, when there is one.
String? errorCodeOf(DioException e) {
  final data = e.response?.data;
  return data is Map ? data['code']?.toString() : null;
}

/// [NextRideAcceptOutcome] for a failed accept.
NextRideAcceptOutcome nextRideAcceptOutcomeOf(Object error) {
  if (error is! DioException) return NextRideAcceptOutcome.failed;
  if (isCashJobBlockedError(error)) return NextRideAcceptOutcome.cashBlocked;
  final status = error.response?.statusCode;
  if (status == 409 && errorCodeOf(error) == 'next_ride_unavailable') {
    return NextRideAcceptOutcome.unavailable;
  }
  if (status == 409 || status == 403) return NextRideAcceptOutcome.gone;
  return NextRideAcceptOutcome.failed;
}

/// [NextRideAcceptOutcome] for a 200 accept body.
NextRideAcceptOutcome nextRideAcceptBodyOutcome(Object? body) =>
    body is Map && body['queued'] == true
    ? NextRideAcceptOutcome.queued
    : NextRideAcceptOutcome.notQueued;

/// 404 `{"code":"no_next_ride"}` from GET /jobs/next or POST /jobs/:id/unqueue.
bool isNoNextRideError(Object error) =>
    error is DioException && error.response?.statusCode == 404;

/// Back-to-back ride calls. Plain [Dio] (like the food service) so callers see
/// the [DioException] and can branch on the body's `code`.
abstract class NextRideApiService {
  /// POST /api/driver/jobs/:id/accept on a next-ride offer.
  Future<NextRideAcceptOutcome> accept(String jobId);

  /// GET /api/driver/jobs/next; null on 404 `no_next_ride`.
  Future<Map<String, dynamic>?> getNextRide();

  /// POST /api/driver/jobs/:id/unqueue. Throws on failure; a 404
  /// (`no_next_ride`) means it is no longer queued for this driver.
  Future<void> unqueue(String jobId);
}

@LazySingleton(as: NextRideApiService)
class NextRideApiServiceImpl implements NextRideApiService {
  NextRideApiServiceImpl(this._dio);

  final Dio _dio;

  @override
  Future<NextRideAcceptOutcome> accept(String jobId) async {
    try {
      final res = await _dio.post(
        Endpoints.driverJobsAccept.replaceAll(':id', jobId),
      );
      return nextRideAcceptBodyOutcome(res.data);
    } catch (e) {
      return nextRideAcceptOutcomeOf(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> getNextRide() async {
    try {
      final res = await _dio.get(Endpoints.driverJobsNext);
      final data = res.data;
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      if (isNoNextRideError(e)) return null;
      rethrow;
    }
  }

  @override
  Future<void> unqueue(String jobId) async {
    await _dio.post(Endpoints.driverJobsUnqueue.replaceAll(':id', jobId));
  }
}

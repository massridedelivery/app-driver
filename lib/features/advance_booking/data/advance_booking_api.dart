import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/advance_booking/domain/advance_eligibility.dart';
import 'package:massdrive/features/advance_booking/domain/advance_errors.dart';
import 'package:massdrive/features/advance_booking/domain/advance_ride.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';

/// The driver's advance booking endpoints (backend `advanceboard`). A
/// refusal with a body is thrown as [AdvanceBookingException].
class AdvanceBookingApi {
  const AdvanceBookingApi(this._dio);

  final Dio _dio;

  /// `GET /api/driver/advance-booking/config` → `{enabled}`. Any failure
  /// (404 on an older server, offline, 5xx) reads as off.
  Future<bool> enabled() async {
    try {
      final res = await _dio.get<dynamic>(Endpoints.driverAdvanceBookingConfig);
      final data = res.data;
      return data is Map && data['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<AdvanceEligibility> eligibility() => _call(() async {
    final res = await _dio.get<dynamic>(Endpoints.driverAdvanceJobsEligibility);
    final data = res.data;
    return AdvanceEligibility.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  });

  /// The board, soonest first. [lat]/[lng] limit it to the admin's radius
  /// and add `distance_from_you_km`; [day] (a Bangkok day) limits it to one
  /// day, otherwise now to 31 days ahead.
  Future<List<AdvanceRide>> board({
    double? lat,
    double? lng,
    double? radiusKm,
    DateTime? day,
  }) => _call(() async {
    final res = await _dio.get<dynamic>(
      Endpoints.driverAdvanceJobs,
      queryParameters: {
        if (lat != null && lng != null) 'lat': lat,
        if (lat != null && lng != null) 'lng': lng,
        if (radiusKm != null) 'radius_km': radiusKm,
        if (day != null) 'date': bangkokDateParam(day),
      },
    );
    return AdvanceRide.listFrom(res.data);
  });

  /// "งานของฉัน": the rides this driver holds, soonest first.
  Future<List<AdvanceRide>> mine() => _call(() async {
    final res = await _dio.get<dynamic>(Endpoints.driverAdvanceJobsMine);
    return AdvanceRide.listFrom(res.data);
  });

  /// Claims [id]; returns the ride as now held.
  Future<AdvanceRide?> claim(String id) => _call(() async {
    final res = await _dio.post<dynamic>(Endpoints.driverAdvanceJobClaim(id));
    final data = res.data;
    return data is Map
        ? AdvanceRide.fromJson(Map<String, dynamic>.from(data))
        : null;
  });

  Future<AdvanceReleaseResult> release(String id) => _call(() async {
    final res = await _dio.post<dynamic>(Endpoints.driverAdvanceJobRelease(id));
    final data = res.data;
    return AdvanceReleaseResult.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  });

  /// "กำลังไป": the ride is accepted for the driver (job_accepted follows).
  Future<void> start(String id) => _call(() async {
    await _dio.post<dynamic>(Endpoints.driverAdvanceJobStart(id));
  });

  /// "ลูกค้าไม่มา": closes the ride; returns the customer's no-show fee.
  Future<double> noShow(String jobId) => _call(() async {
    final res = await _dio.post<dynamic>(Endpoints.driverJobNoShow(jobId));
    final fee = res.data is Map ? (res.data as Map)['no_show_fee'] : null;
    return fee is num ? fee.toDouble() : 0;
  });

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw asAdvanceError(e);
    }
  }
}

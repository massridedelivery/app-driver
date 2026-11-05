import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/referral/domain/driver_referral.dart';

class ReferralApi {
  const ReferralApi(this._dio);

  final Dio _dio;

  /// The invite screen. The first view creates the driver's code.
  Future<ReferralInfo> get() async {
    final res = await _dio.get<dynamic>(Endpoints.driverReferral);
    final data = res.data;
    return ReferralInfo.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  /// Applies a referral code (spaces and case ignored by the backend).
  /// Throws [ReferralApplyException] on a 400; returns `referred_by`.
  Future<ReferralProgress?> apply(String code) async {
    try {
      final res = await _dio.post<dynamic>(
        Endpoints.driverReferralApply,
        data: {'code': code.trim()},
      );
      final by = res.data is Map ? (res.data as Map)['referred_by'] : null;
      return by is Map
          ? ReferralProgress.fromJson(Map<String, dynamic>.from(by))
          : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ReferralApplyException.from(e);
      }
      rethrow;
    }
  }
}

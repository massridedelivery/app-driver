import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// Result of a service-area check (SCRUM-99).
class ServiceAreaResult {
  /// True when the zone is open for the requested service. Missing/unknown =>
  /// true (fail-open): only an explicit `available:false` blocks.
  final bool available;

  /// Human-readable area/province for the driver's current position.
  final String? areaName;

  /// Optional zone-specific override message from the backend.
  final String? message;

  const ServiceAreaResult({
    required this.available,
    this.areaName,
    this.message,
  });

  /// Fail-open default — never blocks the driver.
  static const ServiceAreaResult open = ServiceAreaResult(available: true);

  factory ServiceAreaResult.fromJson(Map<String, dynamic> j) => ServiceAreaResult(
        // Only a literal false blocks; anything else (true/absent) is open.
        available: j['available'] != false,
        areaName: j['area_name']?.toString(),
        message: j['message']?.toString(),
      );
}

/// Service-area gate (SCRUM-99), the same endpoint the customer app uses.
///
/// FAIL-OPEN by design: any error, missing endpoint, or unparseable response
/// returns [ServiceAreaResult.open] so a transient failure never strands the
/// driver offline — only a clear `available:false` blocks going online.
class ServiceAreaService {
  ServiceAreaService._();
  static final ServiceAreaService instance = ServiceAreaService._();

  Future<ServiceAreaResult> check({
    required double lat,
    required double lng,
    required String service,
  }) async {
    try {
      final res = await getIt<Dio>().get(
        Endpoints.serviceAreaCheck,
        queryParameters: {'lat': lat, 'lng': lng, 'service': service},
      );
      final data = res.data;
      if (data is Map) {
        return ServiceAreaResult.fromJson(Map<String, dynamic>.from(data));
      }
      return ServiceAreaResult.open;
    } catch (e) {
      if (kDebugMode) debugPrint('ServiceAreaService.check fail-open: $e');
      return ServiceAreaResult.open;
    }
  }
}

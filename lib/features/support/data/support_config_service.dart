import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/constants/support_constants.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// Loads runtime app config (`GET /api/config/support`) and caches the
/// call-center number into [SupportConstant] so the help screen shows the
/// server-configured number instead of a hardcoded one.
///
/// Fire-and-forget at startup: on any failure the number stays empty and the
/// help UI falls back to "unavailable" rather than dialing a wrong number.
Future<void> loadSupportConfig() async {
  try {
    final res = await getIt<Dio>().get(Endpoints.configSupport);
    final data = res.data;
    final phone = (data is Map && data['support_phone'] != null)
        ? data['support_phone'].toString().trim()
        : '';
    if (phone.isNotEmpty) {
      SupportConstant.callCenterNumber = phone;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('loadSupportConfig failed: $e');
  }
}

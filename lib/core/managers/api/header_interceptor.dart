import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/app_constants.dart';
import 'package:massdrive/core/utils/devices_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeaderInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(Constant.languageCode);

    options.headers['content-type'] = 'application/json';
    options.headers['platform-id'] = 2; // Android/iOS App

    if (languageCode != null) {
      options.headers['content-language'] = languageCode;
    }

    // Set each device header independently so one failing lookup doesn't drop
    // the others. device_info_plus can throw a null-cast TypeError on some
    // devices — when it does we just omit that one header instead of all three.
    options.headers['device-models'] = Device.isAndroid ? 'Android' : 'iOS';
    try {
      options.headers['app-version'] = await Device.getAppVersion();
    } catch (e) {
      if (kDebugMode) debugPrint('HeaderInterceptor: app-version unavailable: $e');
    }
    try {
      options.headers['os-device'] = await Device.getOSVersion();
    } catch (e) {
      if (kDebugMode) debugPrint('HeaderInterceptor: os-device unavailable: $e');
    }

    return handler.next(options);
  }
}

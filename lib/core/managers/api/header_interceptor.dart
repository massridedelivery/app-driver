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

    try {
      options.headers['app-version'] = await Device.getAppVersion();
      options.headers['device-models'] = Device.isAndroid ? 'Android' : 'iOS';
      options.headers['os-device'] = await Device.getOSVersion();
    } catch (e) {
      debugPrint('HeaderInterceptor Error: $e');
    }

    return handler.next(options);
  }
}

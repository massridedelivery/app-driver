import 'package:dio/dio.dart';
import 'package:massdrive/core/managers/api/logs/app_dio_logs.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppDioLoggerInterceptor extends TalkerDioLogger {
  final Talker _talker;

  AppDioLoggerInterceptor(this._talker)
    : super(
        talker: _talker,
        settings: const TalkerDioLoggerSettings(enabled: false),
      );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[TalkerDioLogger.kDioLogsTimeStampKey] =
        DateTime.now().millisecondsSinceEpoch;

    super.onRequest(options, handler);

    try {
      final message = options.extra['feature'] ?? options.path;
      final httpLog = AppDioRequestLog(
        message,
        requestOptions: options,
        settings: settings,
      );
      _talker.logCustom(httpLog);
    } catch (_) {
      //pass
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);

    try {
      final message =
          response.requestOptions.extra['feature'] ??
          response.requestOptions.path;
      final httpLog = AppDioResponseLog(
        message,
        settings: settings,
        response: response,
      );
      _talker.logCustom(httpLog);
    } catch (_) {
      //pass
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);

    try {
      final message =
          err.requestOptions.extra['feature'] ?? err.requestOptions.path;
      final httpErrorLog = AppDioErrorLog(
        message,
        dioException: err,
        settings: settings,
      );
      _talker.logCustom(httpErrorLog);
    } catch (_) {
      //pass
    }
  }
}

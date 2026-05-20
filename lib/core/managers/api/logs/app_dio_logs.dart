import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:massdrive/core/utils/string_util.dart';
import 'package:talker_dio_logger/dio_logs.dart';
import 'package:talker_flutter/talker_flutter.dart';

const _encoder = JsonEncoder.withIndent('  ');
const _hiddenValue = '*****';

class AppDioRequestLog extends DioRequestLog {
  AppDioRequestLog(
    super.message, {
    required super.requestOptions,
    required super.settings,
  });

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    var msg = '[$title] $message';

    final queryParameters = Map.of(requestOptions.queryParameters);
    final data = requestOptions.data;
    final headers = Map.from(requestOptions.headers);

    final tid = headers['tid'];
    if (tid != null) {
      msg += '\nTID: $tid';
    }

    msg += '\nEndPoint: ${requestOptions.extra['endPoint'] ?? requestOptions.path}';

    try {
      if (queryParameters.isNotEmpty) {
        final prettyQueryParameters = _encoder.convert(queryParameters);
        msg += '\nParameters: ${prettyQueryParameters.truncateTo(500)}';
      }

      if (data != null) {
        // If data is FormData, convert it to a map for better readability
        if (data is FormData) {
          final formDataMap = <String, dynamic>{};
          for (var field in data.fields) {
            formDataMap[field.key] = field.value;
          }
          for (var file in data.files) {
            formDataMap[file.key] = {
              'filename': file.value.filename,
              'contentType': file.value.contentType.toString(),
              'bytes': file.value.length,
            };
          }

          msg += '\nData: ${_encoder.convert(formDataMap).truncateTo(500)}';
        } else {
          final prettyData = _encoder.convert(data);
          msg += '\nData: ${prettyData.truncateTo(500)}';
        }
      }

      if (headers.isNotEmpty) {
        // HTTP headers are case-insensitive by standard
        _replaceHiddenHeaders(headers);

        final prettyHeaders = _encoder.convert(headers);
        msg += '\nHeaders: ${prettyHeaders.truncateTo(300)}';
      }
    } catch (_) {
      msg = super.generateTextMessage(timeFormat: timeFormat);
    }
    return msg;
  }

  void _replaceHiddenHeaders(Map<dynamic, dynamic> headers) {
    // HTTP headers are case-insensitive by standard
    final lowerCaseHeaders = <String, String>{};
    headers.forEach((key, value) {
      lowerCaseHeaders[key.toLowerCase()] = key;
    });

    for (final hiddenHeader in settings.hiddenHeaders) {
      final lowerCaseHiddenHeader = hiddenHeader.toLowerCase();
      if (lowerCaseHeaders.containsKey(lowerCaseHiddenHeader)) {
        final originalHeader = lowerCaseHeaders[lowerCaseHiddenHeader]!;
        headers[originalHeader] = _hiddenValue;
      }
    }
  }
}

class AppDioResponseLog extends DioResponseLog {
  AppDioResponseLog(
    super.message, {
    required super.response,
    required super.settings,
  });

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    var msg = '[$title] $message';

    if (responseTime != null) {
      msg += ' | $responseTime ms';
    }

    final responseMessage = response.statusMessage;
    final data = response.data;
    final headers = response.headers.map;

    final tid = headers['tid'];
    if (tid != null) {
      msg += '\nTID: $tid';
    }

    msg += '\nEndPoint: ${response.requestOptions.extra['endPoint'] ?? response.requestOptions.path}';
    msg += '\nStatus: ${response.statusCode}';
    msg += '\nMessage: $responseMessage';

    try {
      if (data != null) {
        final prettyData =
            settings.responseDataConverter?.call(response) ??
            _encoder.convert(data);
        msg += '\nData: ${prettyData.truncateTo(500)}';
      }
      if (headers.isNotEmpty) {
        final prettyHeaders = _encoder.convert(headers);
        msg += '\nHeaders: ${prettyHeaders.truncateTo(300)}';
      }
    } catch (_) {
      msg = super.generateTextMessage(timeFormat: timeFormat);
    }
    return msg;
  }
}

class AppDioErrorLog extends DioErrorLog {
  AppDioErrorLog(
    super.title, {
    required super.dioException,
    required super.settings,
  });

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    var msg = '[$title] $message';

    if (responseTime != null) {
      msg += ' | $responseTime ms';
    }

    final responseMessage = dioException.message;
    final statusCode = dioException.response?.statusCode;
    final data = dioException.response?.data;
    final headers = dioException.response?.headers;

    final tid = headers?['tid'];
    if (tid != null) {
      msg += '\nTID: $tid';
    }

    msg += '\nEndPoint: ${dioException.requestOptions.extra['endPoint'] ?? dioException.requestOptions.path}';

    if (statusCode != null) {
      msg += '\nStatus: ${dioException.response?.statusCode}';
    }

    if (responseMessage != null) {
      msg += '\nMessage: $responseMessage';
    }

    if (data != null) {
      final prettyData = _encoder.convert(data);
      msg += '\nData: ${prettyData.truncateTo(500)}';
    }

    if (!(headers?.isEmpty ?? true)) {
      final prettyHeaders = _encoder.convert(headers!.map);
      msg += '\nHeaders: ${prettyHeaders.truncateTo(300)}';
    }

    return msg;
  }
}

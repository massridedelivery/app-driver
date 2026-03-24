// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ExceptionHandle {
  static const int success = 200;
  static const int success_not_content = 204;
  static const int not_modified = 304;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int not_found = 404;

  static const int net_error = 1000;
  static const int parse_error = 1001;
  static const int socket_error = 1002;
  static const int http_error = 1003;
  static const int connect_timeout_error = 1004;
  static const int send_timeout_error = 1005;
  static const int receive_timeout_error = 1006;
  static const int cancel_error = 1007;
  static const int unknown_error = 9999;

  static final Map<int, NetError> _errorMap = <int, NetError>{
    net_error: const NetError(net_error, 'network error！'),
    parse_error: const NetError(parse_error, 'Parse error'),
    socket_error: const NetError(socket_error, 'Socket error'),
    http_error: const NetError(http_error, 'Http error'),
    connect_timeout_error: const NetError(
      connect_timeout_error,
      'Connection TimeOut',
    ),
    send_timeout_error: const NetError(
      send_timeout_error,
      'Send Connection TimeOut',
    ),
    receive_timeout_error: const NetError(
      receive_timeout_error,
      'Receive Connection TimeOut',
    ),
    cancel_error: const NetError(cancel_error, 'Cancel error'),
    unknown_error: const NetError(unknown_error, 'Unknown error'),
  };

  static NetError handleException(dynamic error) {
    debugPrint(error.toString());
    if (error is DioException) {
      if (error.type.errorCode == 0) {
        return _handleException(error.error);
      } else {
        return _errorMap[error.type.errorCode]!;
      }
    } else {
      return _handleException(error);
    }
  }

  static NetError _handleException(dynamic error) {
    int errorCode = unknown_error;
    if (error is SocketException) {
      errorCode = socket_error;
    }
    if (error is HttpException) {
      errorCode = http_error;
    }
    if (error is FormatException) {
      errorCode = parse_error;
    }
    return _errorMap[errorCode]!;
  }
}

class NetError {
  const NetError(this.code, this.msg);

  final int code;
  final String msg;
}

extension DioErrorTypeExtension on DioExceptionType {
  int get errorCode => [
    ExceptionHandle.connect_timeout_error,
    ExceptionHandle.send_timeout_error,
    ExceptionHandle.receive_timeout_error,
    0,
    0,
    ExceptionHandle.cancel_error,
    0,
    ExceptionHandle.unknown_error,
  ][index];
}

class ErrorCodes {
  static const String backendError = 'backend_error';
  static const String badRequest = 'bad_request';
  static const String brandNotSupported = 'brand_not_supported';
  static const String documentsLocked = 'documents_locked';
  static const String duplicateCard = 'duplicate_card';
  static const String usedToken = 'used_token';
  static const String invalidCard = 'invalid_card';
}

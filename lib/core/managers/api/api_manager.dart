import 'dart:async';
import 'package:massdrive/core/auth/session_trail.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart' as dio_client;
import 'package:dio/io.dart';
import 'package:get_storage/get_storage.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/app_constants.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/core/managers/api/app_exception.dart';
import 'package:massdrive/core/managers/api/profile_error_interceptor.dart';
import 'package:massdrive/core/managers/api/logs/app_dio_logger_interceptor.dart';
import 'package:massdrive/core/managers/api/refresh/app_dio_refreshtoken_interceptor.dart';
import 'package:massdrive/core/managers/logger_manager.dart';
import 'package:massdrive/core/utils/devices_util.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/core/utils/device_language.dart';

part 'api_manager.g.dart';

class ResponseData {
  ResponseData({
    required this.data,
    required this.isSuccessful,
    required this.errorStatusCode,
  });

  dynamic data;
  bool isSuccessful;
  int errorStatusCode;
}

extension ResponseDataExtension on ResponseData {
  dynamic get decodedData {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return null;
  }
}

class ApiManager {
  factory ApiManager(Ref ref) =>
      ApiManager._internal(ref, getIt<dio_client.Dio>());

  String baseUrl = EnvironmentConfig.apiUrl;
  final dio_client.Dio dio;
  final box = GetStorage();
  final _secureStorage = SecureStorageManager();

  late final Ref ref;

  ApiManager._internal(this.ref, this.dio);

  /// Builds a [ResponseData]. A 401 on a request that carried a bearer token
  /// first tries a refresh and one retry: writes use `validateStatus: (_) =>
  /// true`, so their 401s never reach Dio's `onError` and the refresh
  /// interceptor. Only a refused refresh (or a retry that 401s again) ends the
  /// session, via [SessionNotifier], which sends the router back to login. A
  /// refresh that can't reach the server keeps the session. Auth calls
  /// (login/OTP) carry no bearer token, so their 401s are left alone.
  Future<ResponseData> _toResponseData(dio_client.Response response) async {
    var res = response;
    final sent = bearerToken(res.requestOptions.headers);
    if (res.statusCode == 401 && sent != null) {
      res = await _afterUnauthorized(res, sent);
    }
    final code = res.statusCode ?? 0;
    return ResponseData(
      data: res.data,
      isSuccessful: code == 200 || code == 201,
      errorStatusCode: code,
    );
  }

  Future<dio_client.Response> _afterUnauthorized(
    dio_client.Response res,
    String sentToken,
  ) async {
    final path = maskedPath(res.requestOptions.path);
    final refresher = dio.interceptors
        .whereType<AppDioRefreshTokenInterceptor>()
        .firstOrNull;
    if (refresher != null) {
      final renewal = await refresher.renewAfter401(sentToken);
      final token = renewal.token;
      if (token != null) {
        SessionTrail.step('api 401 $path, retried after a refresh');
        final options = res.requestOptions
          ..headers['Authorization'] = 'Bearer $token';
        try {
          final retried = await dio.fetch<dynamic>(options);
          if (retried.statusCode != 401) return retried;
          res = retried;
        } catch (_) {
          // Not replayable (a sent multipart body) or offline: the session
          // was renewed, so it isn't dead — report this request as failed.
          return res;
        }
      } else if (!renewal.sessionEnded) {
        SessionTrail.step('api 401 $path, session kept');
        return res;
      }
    }
    unawaited(
      SessionNotifier.instance.notifySessionExpired(reason: 'api 401 $path'),
    );
    return res;
  }

  Future<ResponseData> fetchApi({
    required String endPoint,
    required String method,
    required String feature,
    String? baseUrl,
    String? stringBody,
    String? contentType,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool encodeBody = true,
    bool addContentLang = true,
  }) async {
    // Configure Dio for Proxyman on first API call
    _configureDio();

    var url = Uri.parse((baseUrl ?? this.baseUrl) + endPoint);

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(Constant.languageCode);

    dio.options.preserveHeaderCase = true;

    dio.options.headers.clear();
    dio.options.headers['content-type'] = contentType ?? 'application/json';
    dio.options.headers['platform-id'] = 2;

    if (languageCode != null) {
      dio.options.headers['content-language'] = languageCode;
    }
    dio.options.headers['Accept-Language'] = deviceLanguageTag();
    dio.options.headers['X-Lang'] = deviceLangCode();

    try {
      dio.options.headers['app-version'] = await Device.getAppVersion();
      dio.options.headers['device-models'] = Device.isAndroid
          ? 'Android'
          : 'iOS';
      dio.options.headers['os-device'] = await Device.getOSVersion();
    } catch (e) {
      debugPrint('ApiManager Header Error: $e');
    }

    try {
      switch (method) {
        case 'GET':
          var data = body != null ? jsonEncode(body).toString() : null;

          var response = await dio.get(
            url.toString(),
            data: data,
            queryParameters: queryParams,
            options: dio_client.Options(
              extra: {'feature': feature, 'endPoint': endPoint},
            ),
          );

          return await _toResponseData(response);

        case 'POST':
          dynamic finalBody;
          if (stringBody != null) {
            finalBody = stringBody;
          } else {
            finalBody = encodeBody ? jsonEncode(body) : body;
          }
          var response = await dio.post(
            url.toString(),
            data: finalBody,
            queryParameters: queryParams,
            options: dio_client.Options(
              followRedirects: false,
              validateStatus: (status) {
                return true;
              },
              extra: {'feature': feature, 'endPoint': endPoint},
            ),
          );
          return await _toResponseData(response);

        case 'PUT':
          var response = await dio.put(
            url.toString(),
            data: jsonEncode(body),
            queryParameters: queryParams,
            options: dio_client.Options(
              followRedirects: false,
              validateStatus: (status) {
                return true;
              },
              extra: {'feature': feature, 'endPoint': endPoint},
            ),
          );

          return await _toResponseData(response);

        case 'PATCH':
          var response = await dio.patch(
            url.toString(),
            data: jsonEncode(body),
            queryParameters: queryParams,
            options: dio_client.Options(
              followRedirects: false,
              validateStatus: (status) {
                return true;
              },
              extra: {'feature': feature, 'endPoint': endPoint},
            ),
          );

          return await _toResponseData(response);

        case 'DELETE':
          var response = await dio.delete(
            url.toString(),
            data: jsonEncode(body),
            queryParameters: queryParams,
            options: dio_client.Options(
              followRedirects: false,
              validateStatus: (status) {
                return true;
              },
              extra: {'feature': feature, 'endPoint': endPoint},
            ),
          );

          return await _toResponseData(response);
      }
    } on SocketException {
      throw const AppException('No Internet Connection');
    } on TimeoutException {
      throw const AppException('Request Timeout');
    } on FormatException catch (e) {
      throw AppException('Format Exception: $e');
    } catch (exc) {
      throw ApiException.fromDioError(exc);
    }
    throw const AppException('Unexpected error: No response from API method.');
  }

  // MARK: upload Media
  Future<ResponseData> uploadMedia({
    required String endPoint,
    required Object? data,
    String? baseUrl,
    String? contentType,
    void Function(int, int)? onSendProgress,
  }) async {
    _configureDio();

    var url = Uri.parse((baseUrl ?? this.baseUrl) + endPoint);

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(Constant.languageCode);

    dio.options.preserveHeaderCase = true;

    dio.options.headers.clear();
    dio.options.headers['content-type'] = contentType ?? 'multipart/form-data';
    dio.options.headers['app-version'] = await Device.getAppVersion();
    dio.options.headers['device-models'] = Device.isAndroid ? 'Android' : 'iOS';
    dio.options.headers['os-device'] = await Device.getOSVersion();
    dio.options.headers['platform-id'] = 2;

    if (languageCode != null) {
      dio.options.headers['content-language'] = languageCode;
    }
    dio.options.headers['Accept-Language'] = deviceLanguageTag();
    dio.options.headers['X-Lang'] = deviceLangCode();

    final accessToken = await _secureStorage.read(SecureStorageKey.accessToken);
    if (accessToken != null) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final response = await dio.post(
        url.toString(),
        data: data,
        options: dio_client.Options(
          followRedirects: false,
          validateStatus: (status) {
            return true;
          },
        ),
        onSendProgress: onSendProgress,
      );
      return await _toResponseData(response);
    } catch (exc) {
      throw ApiException.fromDioError(exc);
    }
  }

  void _configureDio() {
    final addressProxyMan = box.read('proxyManAddress') as String?;
    if (addressProxyMan?.isNotEmpty == true) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) {
            return true;
          };
          client.findProxy = (uri) {
            return 'PROXY $addressProxyMan';
          };
          return client;
        },
      );
    }
  }
}

@riverpod
ApiManager apiManager(Ref ref) {
  return ApiManager(ref);
}

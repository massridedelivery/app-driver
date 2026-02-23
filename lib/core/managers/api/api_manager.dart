import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio_client;
import 'package:dio/io.dart';
import 'package:get_storage/get_storage.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/app_constants.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/core/managers/api/app_exception.dart';
import 'package:massdrive/core/managers/api/logs/app_dio_logger_interceptor.dart';
import 'package:massdrive/core/managers/api/refresh/app_dio_refreshtoken_interceptor.dart';
import 'package:massdrive/core/managers/logger_manager.dart';
import 'package:massdrive/core/utils/devices_util.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  factory ApiManager(Ref ref) => ApiManager._internal(ref);

  String baseUrl = EnvironmentConfig.apiUrl;
  final dio = dio_client.Dio();
  final box = GetStorage();
  final _secureStorage = SecureStorageManager();

  late final Ref ref;

  ApiManager._internal(this.ref) {
    dio.interceptors.add(
      AppDioLoggerInterceptor(LoggerManager.instance.talker),
    );
    dio.interceptors.add(
      AppDioRefreshTokenInterceptor(
        secureStorage: _secureStorage,
        dio: dio,
        authController: ref.read(authControllerProvider.notifier),
      ),
    );
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
    dio.options.headers['app-version'] = await Device.getAppVersion();
    dio.options.headers['device-models'] = Device.isAndroid ? 'Android' : 'iOS';
    dio.options.headers['os-device'] = await Device.getOSVersion();
    dio.options.headers['platform-id'] = 2;

    if (languageCode != null) {
      dio.options.headers['content-language'] = languageCode;
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

          var decodedData = response.data;
          final isSuccessful =
              response.statusCode == 200 || response.statusCode == 201;
          return ResponseData(
            data: decodedData,
            isSuccessful: isSuccessful,
            errorStatusCode: response.statusCode ?? 0,
          );

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
          var decodedData = response.data;
          final isSuccessful =
              response.statusCode == 200 || response.statusCode == 201;
          return ResponseData(
            data: decodedData,
            isSuccessful: isSuccessful,
            errorStatusCode: response.statusCode ?? 0,
          );

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

          var decodedData = response.data;
          final isSuccessful =
              response.statusCode == 200 || response.statusCode == 201;
          return ResponseData(
            data: decodedData,
            isSuccessful: isSuccessful,
            errorStatusCode: response.statusCode ?? 0,
          );

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

          var decodedData = response.data;
          final isSuccessful =
              response.statusCode == 200 || response.statusCode == 201;
          return ResponseData(
            data: decodedData,
            isSuccessful: isSuccessful,
            errorStatusCode: response.statusCode ?? 0,
          );

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

          var decodedData = response.data;
          final isSuccessful =
              response.statusCode == 200 || response.statusCode == 201;
          return ResponseData(
            data: decodedData,
            isSuccessful: isSuccessful,
            errorStatusCode: response.statusCode ?? 0,
          );
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
      final isSuccessful =
          response.statusCode == 200 || response.statusCode == 201;
      return ResponseData(
        data: response.data,
        isSuccessful: isSuccessful,
        errorStatusCode: response.statusCode ?? 0,
      );
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

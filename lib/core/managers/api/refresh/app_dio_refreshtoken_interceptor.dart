import 'dart:async';

import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/features/auth/data/models/auth_token_model.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';

class AppDioRefreshTokenInterceptor extends Interceptor {
  AppDioRefreshTokenInterceptor({
    required this.secureStorage,
    required this.dio,
    this.authController,
    this.onTokenExpired,
  });

  final SecureStorageManager secureStorage;
  final Dio dio;
  final AuthController? authController;
  final FutureOr<void> Function()? onTokenExpired;

  static Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isRefreshTokenRequest(options)) {
      return handler.next(options);
    }

    final accessToken = await secureStorage.read(SecureStorageKey.accessToken);
    if (accessToken == null) {
      return handler.next(options);
    }

    final isTokenExpired = JwtDecoder.isExpired(accessToken);

    if (isTokenExpired) {
      try {
        final newAccessToken = await _lockAndRefreshToken();
        if (newAccessToken != null) {
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          return handler.next(options);
        } else {
          options.headers.remove('Authorization');
          return handler.next(options);
        }
      } catch (e) {
        options.headers.remove('Authorization');
        return handler.next(options);
      }
    } else {
      options.headers['Authorization'] = 'Bearer $accessToken';
      return handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isUnauthorized(err) || _isRefreshTokenRequest(err.requestOptions)) {
      return handler.next(err);
    }

    try {
      final newAccessToken = await _lockAndRefreshToken();
      if (newAccessToken != null) {
        final response = await _retryRequest(
          err.requestOptions,
          newAccessToken,
        );
        return handler.resolve(response);
      } else {
        return handler.next(err);
      }
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<String?> _lockAndRefreshToken() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return secureStorage.read(SecureStorageKey.accessToken);
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await secureStorage.read(
        SecureStorageKey.refreshToken,
      );
      final success = await _refreshToken(refreshToken);

      if (success) {
        return await secureStorage.read(SecureStorageKey.accessToken);
      } else {
        await _clearToken();
        return null;
      }
    } catch (e) {
      await _clearToken();
      return null;
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  bool _isRefreshTokenRequest(RequestOptions options) {
    return options.path.endsWith(Endpoints.refreshToken);
  }

  bool _isUnauthorized(DioException e) {
    if (e.response == null) return false;

    final status = e.response?.statusCode;
    if (status == 401 || status == 403) return true;

    // Check for specific backend error format
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['error'] == 'missing authorization header') {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> _clearToken() async {
    await secureStorage.deleteAll();
    await authController?.refresh();
    await onTokenExpired?.call();
  }

  Future<bool> _refreshToken(String? currentRefresh) async {
    if (currentRefresh?.isEmpty ?? true) return false;

    try {
      final response = await dio.post(
        '${EnvironmentConfig.apiUrl}${Endpoints.refreshToken}',
        data: {'refresh_token': currentRefresh},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      // Support both structured data wrapper and flat json
      final data = response.data;
      final tokenData = data is Map && data.containsKey('data') ? data['data'] : data;
      
      if (tokenData == null) return false;

      final authTokenModel = AuthTokenModel.fromJson(tokenData);
      final accessToken = authTokenModel.accessToken;
      final refreshToken = authTokenModel.refreshToken;

      if (accessToken == null || refreshToken == null) {
        return false;
      }

      await Future.wait([
        secureStorage.write(SecureStorageKey.accessToken, accessToken),
        secureStorage.write(SecureStorageKey.refreshToken, refreshToken),
      ]);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final options = requestOptions;
    requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    return await dio.fetch(options);
  }
}

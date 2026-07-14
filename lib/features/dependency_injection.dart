import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/managers/api/logs/app_dio_logger_interceptor.dart';
import 'package:massdrive/core/managers/api/refresh/app_dio_refreshtoken_interceptor.dart';
import 'package:massdrive/core/managers/api/header_interceptor.dart';
import 'package:massdrive/core/managers/api/profile_error_interceptor.dart';
import 'package:massdrive/core/managers/logger_manager.dart';

import 'dependency_injection.config.dart';

final getIt = GetIt.instance;

@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final secureStorage = SecureStorageManager();

    dio.interceptors.addAll([
      HeaderInterceptor(),
      AppDioRefreshTokenInterceptor(
        secureStorage: secureStorage,
        dio: dio,
        // No authController here to avoid circular dependency in GetIt
        onTokenExpired: () {
          // Add global logout or navigation logic if needed
        },
      ),
      AppDioLoggerInterceptor(LoggerManager.instance.talker),
      ProfileErrorInterceptor(),
    ]);

    return dio;
  }
}

@InjectableInit()
void configureDependencies(String env) => getIt.init(environment: env);

final dioProvider = Provider<Dio>((ref) => GetIt.I<Dio>());

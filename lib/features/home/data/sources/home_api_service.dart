import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/managers/api/api_manager.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_api_service.g.dart';

class HomeApiService {
  final Dio _dio;

  HomeApiService({required Dio dio}) : _dio = dio;

  Future<ResponseData> fetchHome() async {
    final response = await _dio.get(Endpoints.home);
    return ResponseData(
      data: response.data,
      isSuccessful: response.statusCode == 200 || response.statusCode == 201,
      errorStatusCode: response.statusCode ?? 0,
    );
  }

  Future<ResponseData> goOnline() async {
    final response = await _dio.post(Endpoints.driverOnline);
    return ResponseData(
      data: response.data,
      isSuccessful: response.statusCode == 200 || response.statusCode == 201,
      errorStatusCode: response.statusCode ?? 0,
    );
  }

  Future<ResponseData> goOffline() async {
    final response = await _dio.post(Endpoints.driverOffline);
    return ResponseData(
      data: response.data,
      isSuccessful: response.statusCode == 200 || response.statusCode == 201,
      errorStatusCode: response.statusCode ?? 0,
    );
  }

  Future<ResponseData> fetchDriverStatus() async {
    final response = await _dio.get(Endpoints.driverStatus);
    return ResponseData(
      data: response.data,
      isSuccessful: response.statusCode == 200 || response.statusCode == 201,
      errorStatusCode: response.statusCode ?? 0,
    );
  }
}

@riverpod
HomeApiService homeApiService(Ref ref) {
  return HomeApiService(dio: getIt<Dio>());
}

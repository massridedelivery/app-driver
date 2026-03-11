import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/managers/api/api_manager.dart';

abstract class ProfileApiService {
  Future<Response<Map<String, dynamic>>> getProfile();
  Future<Response<Map<String, dynamic>>> updateProfile(Map<String, dynamic> data);
}

@LazySingleton(as: ProfileApiService)
class ProfileApiServiceImpl implements ProfileApiService {
  late final Dio _dio;

  ProfileApiServiceImpl() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://driver-api-dev.nutchaphut.dev',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // Add logging if needed, similar to AuthApiServiceImpl
  }

  @override
  Future<Response<Map<String, dynamic>>> getProfile() async {
    return await _dio.get<Map<String, dynamic>>(
      Endpoints.driverProfile,
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put<Map<String, dynamic>>(
      Endpoints.driverProfile,
      data: data,
    );
  }
}

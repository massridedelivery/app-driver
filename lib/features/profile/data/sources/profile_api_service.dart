import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class ProfileApiService {
  Future<Response<Map<String, dynamic>>> getProfile();
  Future<Response<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data,
  );
}

@LazySingleton(as: ProfileApiService)
class ProfileApiServiceImpl implements ProfileApiService {
  final Dio _dio;

  ProfileApiServiceImpl(this._dio);

  @override
  Future<Response<Map<String, dynamic>>> getProfile() async {
    return await _dio.get<Map<String, dynamic>>(Endpoints.driverProfile);
  }

  @override
  Future<Response<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    return await _dio.put<Map<String, dynamic>>(
      Endpoints.driverProfile,
      data: data,
    );
  }
}

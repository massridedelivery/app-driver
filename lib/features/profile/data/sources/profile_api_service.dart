import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/sources/base_api_service.dart';

abstract class ProfileApiService {
  Future<Response<Map<String, dynamic>>> getProfile();
  Future<Response<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data,
  );
}

@LazySingleton(as: ProfileApiService)
class ProfileApiServiceImpl extends BaseApiService implements ProfileApiService {
  ProfileApiServiceImpl(super.dio);

  @override
  Future<Response<Map<String, dynamic>>> getProfile() async {
    return await get<Map<String, dynamic>>(Endpoints.driverProfile);
  }

  @override
  Future<Response<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    return await put<Map<String, dynamic>>(
      Endpoints.driverProfile,
      data: data,
    );
  }
}

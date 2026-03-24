import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class NotificationApiService {
  Future<Response<Map<String, dynamic>>> registerDevice(
    Map<String, dynamic> data,
  );
}

@LazySingleton(as: NotificationApiService)
class NotificationApiServiceImpl implements NotificationApiService {
  final Dio _dio;

  NotificationApiServiceImpl(this._dio);

  @override
  Future<Response<Map<String, dynamic>>> registerDevice(
    Map<String, dynamic> data,
  ) async {
    return await _dio.post<Map<String, dynamic>>(
      Endpoints.registerDevice,
      data: data,
    );
  }
}

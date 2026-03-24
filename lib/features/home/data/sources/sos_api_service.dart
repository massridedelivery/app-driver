import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class SosApiService {
  Future<Response<Map<String, dynamic>>> triggerSos(Map<String, dynamic> data);
  Future<Response<Map<String, dynamic>>> resolveSos(
    String incidentId,
    Map<String, dynamic> data,
  );
}

@LazySingleton(as: SosApiService)
class SosApiServiceImpl implements SosApiService {
  final Dio _dio;

  SosApiServiceImpl(this._dio);

  @override
  Future<Response<Map<String, dynamic>>> triggerSos(
    Map<String, dynamic> data,
  ) async {
    return await _dio.post<Map<String, dynamic>>(
      Endpoints.sosTrigger,
      data: data,
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> resolveSos(
    String incidentId,
    Map<String, dynamic> data,
  ) async {
    final endpoint = Endpoints.sosResolve.replaceAll(':id', incidentId);
    return await _dio.post<Map<String, dynamic>>(endpoint, data: data);
  }
}

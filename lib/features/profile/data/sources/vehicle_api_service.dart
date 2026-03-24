import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class VehicleApiService {
  Future<Response> toggleVehicleType(String typeId, Map<String, dynamic> data);
}

@LazySingleton(as: VehicleApiService)
class VehicleApiServiceImpl implements VehicleApiService {
  final Dio _dio;

  VehicleApiServiceImpl(this._dio);

  @override
  Future<Response> toggleVehicleType(
    String typeId,
    Map<String, dynamic> data,
  ) async {
    final endpoint = Endpoints.vehicleTypeToggle.replaceAll(':id', typeId);
    return await _dio.patch(endpoint, data: data);
  }
}

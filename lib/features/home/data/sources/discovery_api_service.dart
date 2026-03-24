import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class DiscoveryApiService {
  Future<Response<Map<String, dynamic>>> getHomeFeed(double lat, double lng);
}

@LazySingleton(as: DiscoveryApiService)
class DiscoveryApiServiceImpl implements DiscoveryApiService {
  final Dio _dio;

  DiscoveryApiServiceImpl(this._dio);

  @override
  Future<Response<Map<String, dynamic>>> getHomeFeed(
    double lat,
    double lng,
  ) async {
    return await _dio.get<Map<String, dynamic>>(
      Endpoints.driverDiscoveryHome,
      queryParameters: {'lat': lat, 'lng': lng},
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../data/sources/discovery_api_service.dart';
import '../../domain/repositories/discovery_repository.dart';

@LazySingleton(as: DiscoveryRepository)
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryApiService _apiService;

  DiscoveryRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getHomeFeed(double lat, double lng) async {
    final response = await _apiService.getHomeFeed(lat, lng);
    return response.data ?? {};
  }
}

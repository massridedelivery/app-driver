import 'package:injectable/injectable.dart';
import '../../data/sources/vehicle_api_service.dart';
import '../../domain/repositories/vehicle_repository.dart';

@LazySingleton(as: VehicleRepository)
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleApiService _apiService;

  VehicleRepositoryImpl(this._apiService);

  @override
  Future<void> toggleVehicleType(String typeId, Map<String, dynamic> data) async {
    await _apiService.toggleVehicleType(typeId, data);
  }
}

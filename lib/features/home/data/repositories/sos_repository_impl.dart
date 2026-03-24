import 'package:injectable/injectable.dart';
import '../../data/sources/sos_api_service.dart';
import '../../domain/repositories/sos_repository.dart';

@LazySingleton(as: SosRepository)
class SosRepositoryImpl implements SosRepository {
  final SosApiService _apiService;

  SosRepositoryImpl(this._apiService);

  @override
  Future<void> triggerSos(Map<String, dynamic> data) async {
    await _apiService.triggerSos(data);
  }

  @override
  Future<void> resolveSos(String incidentId, Map<String, dynamic> data) async {
    await _apiService.resolveSos(incidentId, data);
  }
}

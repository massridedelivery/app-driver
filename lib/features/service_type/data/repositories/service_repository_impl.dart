import 'package:massdrive/features/service_type/domain/entities/service_type.dart';
import 'package:massdrive/features/service_type/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final List<ServiceType> _cache = [
    ServiceType(id: "1", name: "Mass Bike", isEnabled: true),
    ServiceType(id: "2", name: "MassFood (Bike)", isEnabled: false),
    ServiceType(id: "3", name: "MassExpress (Bike)", isEnabled: false),
  ];

  @override
  Future<List<ServiceType>> fetchServices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cache;
  }

  @override
  Future<ServiceType> toggleService(String id) async {
    final index = _cache.indexWhere((e) => e.id == id);
    final updated = _cache[index].copyWith(isEnabled: !_cache[index].isEnabled);
    _cache[index] = updated;

    return updated;
  }
}

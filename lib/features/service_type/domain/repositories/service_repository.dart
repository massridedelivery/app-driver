import 'package:massdrive/features/service_type/domain/entities/service_type.dart';

abstract class ServiceRepository {
  Future<List<ServiceType>> fetchServices();

  Future<ServiceType> toggleService(String id);
}

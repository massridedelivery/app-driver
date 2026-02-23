import 'package:massdrive/features/service_type/domain/entities/service_type.dart';
import 'package:massdrive/features/service_type/domain/repositories/service_repository.dart';

class ToggleServiceUseCase {
  final ServiceRepository repository;

  ToggleServiceUseCase(this.repository);

  Future<ServiceType> call(String id) {
    return repository.toggleService(id);
  }
}

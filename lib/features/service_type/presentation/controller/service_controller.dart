import 'package:flutter/cupertino.dart';
import 'package:massdrive/features/service_type/domain/repositories/service_repository.dart';
import 'package:massdrive/features/service_type/domain/usecase/toggle_service_use_case.dart';
import 'package:massdrive/features/service_type/presentation/states/service_state.dart';

class ServiceController extends ChangeNotifier {
  final ToggleServiceUseCase toggleUseCase;
  final ServiceRepository repository;

  ServiceState _state = const ServiceState(services: [], isLoading: false);

  ServiceState get state => _state;

  ServiceController({required this.toggleUseCase, required this.repository});

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final services = await repository.fetchServices();

    _state = _state.copyWith(services: services, isLoading: false);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final updated = await toggleUseCase(id);

    final newList = _state.services.map((s) {
      return s.id == id ? updated : s;
    }).toList();

    _state = _state.copyWith(services: newList);
    notifyListeners();
  }
}

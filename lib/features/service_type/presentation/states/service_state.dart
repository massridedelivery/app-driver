import 'package:massdrive/features/service_type/domain/entities/service_type.dart';

class ServiceState {
  final List<ServiceType> services;
  final bool isLoading;

  const ServiceState({required this.services, required this.isLoading});

  ServiceState copyWith({List<ServiceType>? services, bool? isLoading}) {
    return ServiceState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ServiceType {
  final String id;
  final String name;
  final bool isEnabled;

  const ServiceType({
    required this.id,
    required this.name,
    required this.isEnabled,
  });

  ServiceType copyWith({bool? isEnabled}) {
    return ServiceType(
      id: id,
      name: name,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class VehicleInfo {
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;

  VehicleInfo({
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
  });

  VehicleInfo copyWith({
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? licensePlate,
  }) {
    return VehicleInfo(
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
    };
  }

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      vehicleType: map['vehicleType'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year']?.toInt() ?? 0,
      licensePlate: map['licensePlate'] ?? '',
    );
  }
}

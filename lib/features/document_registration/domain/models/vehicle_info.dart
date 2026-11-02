/// The rider's vehicle as entered in the sign-up vehicle step.
///
/// [model] is the brand and model in one field ("Honda Wave 110i"), sent as
/// `vehicle_model` — the backend has no separate brand field. [province] is
/// the plate's province (one of kThaiProvinces) and [color] a short Thai word.
class VehicleInfo {
  final String vehicleType;
  final String model;
  final int year;
  final String licensePlate;
  final String province;
  final String color;

  VehicleInfo({
    required this.vehicleType,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.province = '',
    this.color = '',
  });

  /// Plate, province and colour all filled in.
  bool get isComplete =>
      licensePlate.trim().isNotEmpty &&
      province.trim().isNotEmpty &&
      color.trim().isNotEmpty;

  VehicleInfo copyWith({
    String? vehicleType,
    String? model,
    int? year,
    String? licensePlate,
    String? province,
    String? color,
  }) {
    return VehicleInfo(
      vehicleType: vehicleType ?? this.vehicleType,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      province: province ?? this.province,
      color: color ?? this.color,
    );
  }

  /// The PUT /api/driver/profile body for this vehicle.
  Map<String, dynamic> toProfileUpdate() {
    return {
      'vehicle_plate': licensePlate,
      'vehicle_province': province,
      'vehicle_color': color,
      'vehicle_model': model,
      'vehicle_year': year,
    };
  }

  /// Only the fields that differ from [before], for an edit: an untouched
  /// field is left out (the backend keeps it) and an empty value is never
  /// sent, since "" would blank the stored one.
  Map<String, dynamic> changesFrom(VehicleInfo? before) {
    final previous = before?.toProfileUpdate() ?? const {};
    return {
      for (final e in toProfileUpdate().entries)
        if (e.value != previous[e.key] &&
            !(e.value is String && (e.value as String).isEmpty) &&
            !(e.value is int && e.value == 0))
          e.key: e.value,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'province': province,
      'color': color,
    };
  }

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      vehicleType: map['vehicleType'] ?? '',
      model: map['model'] ?? '',
      year: map['year']?.toInt() ?? 0,
      licensePlate: map['licensePlate'] ?? '',
      province: map['province'] ?? '',
      color: map['color'] ?? '',
    );
  }
}

/// The sign-up vehicle step is done once the saved vehicle has its plate,
/// province and colour, and the registration book is uploaded.
bool isVehicleStepComplete({
  required VehicleInfo? saved,
  required bool registrationBookUploaded,
}) =>
    (saved?.isComplete ?? false) && registrationBookUploaded;

/// A plate as typed, tidied: trimmed, repeated spaces collapsed.
String normalizePlate(String plate) =>
    plate.trim().replaceAll(RegExp(r'\s+'), ' ');

/// "1กข 1234 กรุงเทพมหานคร", or the plate alone while the province is empty.
String plateWithProvince(String? plate, String? province) {
  final p = (plate ?? '').trim();
  final prov = (province ?? '').trim();
  if (p.isEmpty) return '';
  return prov.isEmpty ? p : '$p $prov';
}

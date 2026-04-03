import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_profile_entity.freezed.dart';
part 'driver_profile_entity.g.dart';

// ignore_for_file: invalid_annotation_target
@freezed
sealed class DriverProfileEntity with _$DriverProfileEntity {
  const factory DriverProfileEntity({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'full_name') required String fullName,
    String? phone,
    @Default(0.0) double rating,
    @JsonKey(name: 'total_trips') @Default(0) int totalTrips,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @Default([]) List<DocumentEntity> documents,
    @JsonKey(name: 'vehicle_type_ids') @Default([]) List<String> vehicleTypeIds,
    @JsonKey(name: 'vehicle_types')
    @Default([])
    List<VehicleTypeEntity> vehicleTypes,
    @JsonKey(name: 'vehicle_plate') String? vehiclePlate,
    @JsonKey(name: 'vehicle_color') String? vehicleColor,
    @JsonKey(name: 'vehicle_model') String? vehicleModel,
    @JsonKey(name: 'vehicle_year') int? vehicleYear,
    @JsonKey(name: 'vehicle_province') String? vehicleProvince,
    @Default(0.0) double balance,
    @JsonKey(name: 'commission_rate') @Default(0.0) double commissionRate,
    @JsonKey(name: 'incentive_tier') String? incentiveTier,
    @JsonKey(name: 'loyalty_points') @Default(0) int loyaltyPoints,
    @JsonKey(name: 'acceptance_rate') @Default(0.0) double acceptanceRate,
    @JsonKey(name: 'cancellation_rate') @Default(0.0) double cancellationRate,
    @JsonKey(name: 'weekly_completed_jobs') @Default(0) int weeklyCompletedJobs,
    @Default('offline') String status,
  }) = _DriverProfileEntity;

  factory DriverProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileEntityFromJson(json);
}

@freezed
sealed class DocumentEntity with _$DocumentEntity {
  const factory DocumentEntity({
    required String type,
    required String status,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'reviewed_at') String? reviewedAt,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
  }) = _DocumentEntity;

  factory DocumentEntity.fromJson(Map<String, dynamic> json) =>
      _$DocumentEntityFromJson(json);
}

@freezed
sealed class VehicleTypeEntity with _$VehicleTypeEntity {
  const factory VehicleTypeEntity({
    required String id,
    required String name,
    @JsonKey(name: 'display_name') required String displayName,
    String? description,
    @JsonKey(name: 'vehicle_class') String? vehicleClass,
    @JsonKey(name: 'base_fare') @Default(0.0) double baseFare,
    @JsonKey(name: 'price_per_km') @Default(0.0) double pricePerKm,
    @JsonKey(name: 'price_per_min') @Default(0.0) double pricePerMin,
    @JsonKey(name: 'min_fare') @Default(0.0) double minFare,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'is_enabled') @Default(false) bool isEnabled,
  }) = _VehicleTypeEntity;

  factory VehicleTypeEntity.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypeEntityFromJson(json);
}

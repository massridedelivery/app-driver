// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_profile_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverProfileEntity _$DriverProfileEntityFromJson(
  Map<String, dynamic> json,
) => _DriverProfileEntity(
  userId: json['user_id'] as String,
  fullName: json['full_name'] as String,
  phone: json['phone'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
  isVerified: json['verified'] as bool? ?? false,
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  vehicleTypeIds:
      (json['vehicle_type_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  vehicleTypes:
      (json['vehicle_types'] as List<dynamic>?)
          ?.map((e) => VehicleTypeEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  vehiclePlate: json['vehicle_plate'] as String?,
  vehicleColor: json['vehicle_color'] as String?,
  vehicleModel: json['vehicle_model'] as String?,
  vehicleYear: (json['vehicle_year'] as num?)?.toInt(),
  vehicleProvince: json['vehicle_province'] as String?,
  balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
  commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
  incentiveTier: json['incentive_tier'] as String?,
  loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
  acceptanceRate: (json['acceptance_rate'] as num?)?.toDouble() ?? 0.0,
  cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
  weeklyCompletedJobs: (json['weekly_completed_jobs'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'offline',
);

Map<String, dynamic> _$DriverProfileEntityToJson(
  _DriverProfileEntity instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'full_name': instance.fullName,
  'phone': instance.phone,
  'rating': instance.rating,
  'total_trips': instance.totalTrips,
  'verified': instance.isVerified,
  'documents': instance.documents,
  'vehicle_type_ids': instance.vehicleTypeIds,
  'vehicle_types': instance.vehicleTypes,
  'vehicle_plate': instance.vehiclePlate,
  'vehicle_color': instance.vehicleColor,
  'vehicle_model': instance.vehicleModel,
  'vehicle_year': instance.vehicleYear,
  'vehicle_province': instance.vehicleProvince,
  'balance': instance.balance,
  'commission_rate': instance.commissionRate,
  'incentive_tier': instance.incentiveTier,
  'loyalty_points': instance.loyaltyPoints,
  'acceptance_rate': instance.acceptanceRate,
  'cancellation_rate': instance.cancellationRate,
  'weekly_completed_jobs': instance.weeklyCompletedJobs,
  'status': instance.status,
};

_DocumentEntity _$DocumentEntityFromJson(Map<String, dynamic> json) =>
    _DocumentEntity(
      type: json['type'] as String,
      status: json['status'] as String,
      mediaUrl: json['media_url'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );

Map<String, dynamic> _$DocumentEntityToJson(_DocumentEntity instance) =>
    <String, dynamic>{
      'type': instance.type,
      'status': instance.status,
      'media_url': instance.mediaUrl,
      'reviewed_at': instance.reviewedAt,
      'rejection_reason': instance.rejectionReason,
    };

_VehicleTypeEntity _$VehicleTypeEntityFromJson(Map<String, dynamic> json) =>
    _VehicleTypeEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      vehicleClass: json['vehicle_class'] as String?,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0.0,
      pricePerKm: (json['price_per_km'] as num?)?.toDouble() ?? 0.0,
      pricePerMin: (json['price_per_min'] as num?)?.toDouble() ?? 0.0,
      minFare: (json['min_fare'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$VehicleTypeEntityToJson(_VehicleTypeEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'description': instance.description,
      'vehicle_class': instance.vehicleClass,
      'base_fare': instance.baseFare,
      'price_per_km': instance.pricePerKm,
      'price_per_min': instance.pricePerMin,
      'min_fare': instance.minFare,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'is_enabled': instance.isEnabled,
    };

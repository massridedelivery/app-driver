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
  verified: json['verified'] as bool? ?? false,
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
  'verified': instance.verified,
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
    );

Map<String, dynamic> _$DocumentEntityToJson(_DocumentEntity instance) =>
    <String, dynamic>{
      'type': instance.type,
      'status': instance.status,
      'media_url': instance.mediaUrl,
      'reviewed_at': instance.reviewedAt,
    };

_VehicleTypeEntity _$VehicleTypeEntityFromJson(Map<String, dynamic> json) =>
    _VehicleTypeEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$VehicleTypeEntityToJson(_VehicleTypeEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'is_enabled': instance.isEnabled,
    };

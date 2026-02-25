// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IncomingJobModel _$IncomingJobModelFromJson(Map<String, dynamic> json) =>
    _IncomingJobModel(
      jobId: json['job_id'] as String,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      pickupAddressDetail: json['pickup_address_detail'] as String,
      dropoffAddressDetail: json['dropoff_address_detail'] as String,
      pickupDistanceKm: (json['pickup_distance_km'] as num).toDouble(),
      dropoffDistanceKm: (json['dropoff_distance_km'] as num).toDouble(),
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      netIncome: (json['net_income'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      points: (json['points'] as num).toInt(),
      serviceType: json['service_type'] as String,
      itemSummary: json['item_summary'] as String,
      timeoutSeconds: (json['timeout_seconds'] as num).toInt(),
    );

Map<String, dynamic> _$IncomingJobModelToJson(_IncomingJobModel instance) =>
    <String, dynamic>{
      'job_id': instance.jobId,
      'pickup_address': instance.pickupAddress,
      'dropoff_address': instance.dropoffAddress,
      'pickup_address_detail': instance.pickupAddressDetail,
      'dropoff_address_detail': instance.dropoffAddressDetail,
      'pickup_distance_km': instance.pickupDistanceKm,
      'dropoff_distance_km': instance.dropoffDistanceKm,
      'pickup_lat': instance.pickupLat,
      'pickup_lng': instance.pickupLng,
      'dropoff_lat': instance.dropoffLat,
      'dropoff_lng': instance.dropoffLng,
      'net_income': instance.netIncome,
      'payment_method': instance.paymentMethod,
      'points': instance.points,
      'service_type': instance.serviceType,
      'item_summary': instance.itemSummary,
      'timeout_seconds': instance.timeoutSeconds,
    };

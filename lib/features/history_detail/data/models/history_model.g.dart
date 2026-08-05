// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryModel _$HistoryModelFromJson(Map<String, dynamic> json) => HistoryModel(
  id: json['id'] as String,
  dateTime: json['date_time'] as String,
  pickupAddress: json['pickup_address'] as String,
  dropoffAddress: json['dropoff_address'] as String,
  distanceKm: (json['distance_km'] as num).toDouble(),
  durationMinute: (json['duration_minute'] as num).toInt(),
  total: (json['total'] as num).toDouble(),
  paymentMethod: json['payment_method'] as String,
  driverNet: (json['driver_net'] as num).toDouble(),
  pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
  pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
  dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
  dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$HistoryModelToJson(HistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date_time': instance.dateTime,
      'pickup_address': instance.pickupAddress,
      'dropoff_address': instance.dropoffAddress,
      'distance_km': instance.distanceKm,
      'duration_minute': instance.durationMinute,
      'total': instance.total,
      'payment_method': instance.paymentMethod,
      'driver_net': instance.driverNet,
      'pickup_lat': instance.pickupLat,
      'pickup_lng': instance.pickupLng,
      'dropoff_lat': instance.dropoffLat,
      'dropoff_lng': instance.dropoffLng,
    };

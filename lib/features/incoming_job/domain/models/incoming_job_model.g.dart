// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IncomingJobModel _$IncomingJobModelFromJson(Map<String, dynamic> json) =>
    _IncomingJobModel(
      jobId: json['id'] as String,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      pickupAddressDetail: json['pickup_address_detail'] as String? ?? '',
      dropoffAddressDetail: json['dropoff_address_detail'] as String? ?? '',
      pickupDistanceKm: (json['pickup_distance_km'] as num?)?.toDouble() ?? 0.0,
      dropoffDistanceKm:
          (json['dropoff_distance_km'] as num?)?.toDouble() ?? 0.0,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      netIncome: (json['fare'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
      serviceType: json['service_type'] as String? ?? 'Saver Bike',
      passengerName: json['passenger_name'] as String? ?? 'Passenger',
      itemSummary: json['item_summary'] as String? ?? '',
      timeoutSeconds: (json['timeout_seconds'] as num?)?.toInt() ?? 30,
      surgeMultiplier: (json['surge_multiplier'] as num?)?.toDouble() ?? 1.0,
      surgeActive: json['surge_active'] as bool? ?? false,
      isScheduled: json['is_scheduled'] as bool? ?? false,
      scheduledAt: json['scheduled_at'] as String?,
      restaurantName: json['restaurant_name'] as String?,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      orderItems:
          (json['order_items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$IncomingJobModelToJson(_IncomingJobModel instance) =>
    <String, dynamic>{
      'id': instance.jobId,
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
      'fare': instance.netIncome,
      'payment_method': instance.paymentMethod,
      'points': instance.points,
      'service_type': instance.serviceType,
      'passenger_name': instance.passengerName,
      'item_summary': instance.itemSummary,
      'timeout_seconds': instance.timeoutSeconds,
      'surge_multiplier': instance.surgeMultiplier,
      'surge_active': instance.surgeActive,
      'is_scheduled': instance.isScheduled,
      'scheduled_at': instance.scheduledAt,
      'restaurant_name': instance.restaurantName,
      'delivery_fee': instance.deliveryFee,
      'subtotal': instance.subtotal,
      'order_items': instance.orderItems,
    };

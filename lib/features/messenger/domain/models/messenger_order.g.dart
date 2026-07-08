// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messenger_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessengerOrder _$MessengerOrderFromJson(Map<String, dynamic> json) =>
    MessengerOrder(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      driverId: json['driver_id'] as String?,
      vehicleTypeId: json['vehicle_type_id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      pickupAddress: json['pickup_address'] as String?,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 0.0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 0.0,
      dropoffAddress: json['dropoff_address'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      packageSizeTier: json['package_size_tier'] as String? ?? '',
      packageWeightKg: (json['package_weight_kg'] as num?)?.toDouble() ?? 0.0,
      packageLengthCm: (json['package_length_cm'] as num?)?.toDouble(),
      packageWidthCm: (json['package_width_cm'] as num?)?.toDouble(),
      packageHeightCm: (json['package_height_cm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      codAmount: (json['cod_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      platformCommission:
          (json['platform_commission'] as num?)?.toDouble() ?? 0.0,
      promoId: json['promo_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      arrivedAtPickupAt: json['arrived_at_pickup_at'] == null
          ? null
          : DateTime.parse(json['arrived_at_pickup_at'] as String),
      pickedUpAt: json['picked_up_at'] == null
          ? null
          : DateTime.parse(json['picked_up_at'] as String),
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      cancelledBy: json['cancelled_by'] as String?,
      cancelReason: json['cancel_reason'] as String?,
    );

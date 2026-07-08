// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messenger_offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessengerOffer _$MessengerOfferFromJson(Map<String, dynamic> json) =>
    MessengerOffer(
      id: json['id'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      pickupAddress: json['pickup_address'] as String?,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 0.0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 0.0,
      dropoffAddress: json['dropoff_address'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      packageSizeTier: json['package_size_tier'] as String? ?? '',
      codAmount: (json['cod_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
    );

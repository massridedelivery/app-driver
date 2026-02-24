// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IncomingJobModel _$IncomingJobModelFromJson(Map<String, dynamic> json) =>
    _IncomingJobModel(
      jobId: json['jobId'] as String,
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      pickupAddressDetail: json['pickupAddressDetail'] as String,
      dropoffAddressDetail: json['dropoffAddressDetail'] as String,
      pickupDistanceKm: (json['pickupDistanceKm'] as num).toDouble(),
      dropoffDistanceKm: (json['dropoffDistanceKm'] as num).toDouble(),
      pickupLat: (json['pickupLat'] as num).toDouble(),
      pickupLng: (json['pickupLng'] as num).toDouble(),
      dropoffLat: (json['dropoffLat'] as num).toDouble(),
      dropoffLng: (json['dropoffLng'] as num).toDouble(),
      netIncome: (json['netIncome'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      points: (json['points'] as num).toInt(),
      serviceType: json['serviceType'] as String,
      itemSummary: json['itemSummary'] as String,
      timeoutSeconds: (json['timeoutSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$IncomingJobModelToJson(_IncomingJobModel instance) =>
    <String, dynamic>{
      'jobId': instance.jobId,
      'pickupAddress': instance.pickupAddress,
      'dropoffAddress': instance.dropoffAddress,
      'pickupAddressDetail': instance.pickupAddressDetail,
      'dropoffAddressDetail': instance.dropoffAddressDetail,
      'pickupDistanceKm': instance.pickupDistanceKm,
      'dropoffDistanceKm': instance.dropoffDistanceKm,
      'pickupLat': instance.pickupLat,
      'pickupLng': instance.pickupLng,
      'dropoffLat': instance.dropoffLat,
      'dropoffLng': instance.dropoffLng,
      'netIncome': instance.netIncome,
      'paymentMethod': instance.paymentMethod,
      'points': instance.points,
      'serviceType': instance.serviceType,
      'itemSummary': instance.itemSummary,
      'timeoutSeconds': instance.timeoutSeconds,
    };

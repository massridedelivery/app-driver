// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryItemApiModel _$HistoryItemApiModelFromJson(Map<String, dynamic> json) =>
    HistoryItemApiModel(
      id: json['id'] as String?,
      type: json['type'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
      jobId: json['job_id'] as String?,
      completedAt: json['completed_at'] as String?,
      earnings: (json['earnings'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$HistoryItemApiModelToJson(
  HistoryItemApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'amount': instance.amount,
  'status': instance.status,
  'description': instance.description,
  'created_at': instance.createdAt,
  'job_id': instance.jobId,
  'completed_at': instance.completedAt,
  'earnings': instance.earnings,
  'distance_km': instance.distanceKm,
  'payment_method': instance.paymentMethod,
  'title': instance.title,
};

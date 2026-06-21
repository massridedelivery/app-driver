// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryItemApiModel _$HistoryItemApiModelFromJson(Map<String, dynamic> json) =>
    HistoryItemApiModel(
      jobId: json['job_id'] as String,
      completedAt: json['completed_at'] as String,
      earnings: (json['earnings'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$HistoryItemApiModelToJson(
  HistoryItemApiModel instance,
) => <String, dynamic>{
  'job_id': instance.jobId,
  'completed_at': instance.completedAt,
  'earnings': instance.earnings,
  'distance_km': instance.distanceKm,
  'payment_method': instance.paymentMethod,
  'type': instance.type,
  'title': instance.title,
  'status': instance.status,
};

HistoryListResponseModel _$HistoryListResponseModelFromJson(
  Map<String, dynamic> json,
) => HistoryListResponseModel(
  data: (json['data'] as List<dynamic>)
      .map((e) => HistoryItemApiModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$HistoryListResponseModelToJson(
  HistoryListResponseModel instance,
) => <String, dynamic>{
  'data': instance.data,
  'page': instance.page,
  'limit': instance.limit,
  'total': instance.total,
};

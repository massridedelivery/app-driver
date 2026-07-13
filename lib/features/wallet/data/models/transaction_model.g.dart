// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'status': instance.status,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
      'job_id': instance.jobId,
      'order_id': instance.orderId,
      'user_id': instance.userId,
      'counterparty_id': instance.counterpartyId,
      'currency': instance.currency,
      'payment_method': instance.paymentMethod,
      'metadata': instance.metadata,
      'commission': instance.commission,
      'discount': instance.discount,
      'platform_fee': instance.platformFee,
      'subtotal': instance.subtotal,
      'completed_at': instance.completedAt?.toIso8601String(),
    };

Map<String, dynamic> _$TransactionListModelToJson(
  TransactionListModel instance,
) => <String, dynamic>{
  'transactions': instance.transactions,
  'total': instance.total,
  'limit': instance.limit,
  'offset': instance.offset,
};

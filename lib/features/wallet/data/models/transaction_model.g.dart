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
    };

Map<String, dynamic> _$TransactionListModelToJson(
  TransactionListModel instance,
) => <String, dynamic>{
  'transactions': instance.transactions,
  'total': instance.total,
};

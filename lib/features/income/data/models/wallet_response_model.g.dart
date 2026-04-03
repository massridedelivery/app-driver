// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletResponseModel _$WalletResponseModelFromJson(Map<String, dynamic> json) =>
    WalletResponseModel(
      cashBalance: (json['cash_balance'] as num).toDouble(),
      creditBalance: (json['credit_balance'] as num).toDouble(),
    );

Map<String, dynamic> _$WalletResponseModelToJson(
  WalletResponseModel instance,
) => <String, dynamic>{
  'cash_balance': instance.cashBalance,
  'credit_balance': instance.creditBalance,
};

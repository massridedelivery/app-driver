// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_overview_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletOverviewModel _$WalletOverviewModelFromJson(Map<String, dynamic> json) =>
    WalletOverviewModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'THB',
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      totalTripsToday: (json['total_trips_today'] as num?)?.toInt() ?? 0,
      isVerified: (json['is_verified'] as bool?) ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now().toUtc(),
    );

Map<String, dynamic> _$WalletOverviewModelToJson(
  WalletOverviewModel instance,
) => <String, dynamic>{
  'balance': instance.balance,
  'currency': instance.currency,
  'today_earnings': instance.todayEarnings,
  'total_trips_today': instance.totalTripsToday,
  'is_verified': instance.isVerified,
  'last_updated': instance.lastUpdated.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_overview_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletOverviewModel _$WalletOverviewModelFromJson(Map<String, dynamic> json) =>
    WalletOverviewModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      withdrawn: (json['withdrawn'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'THB',
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      thisWeekEarnings: (json['this_week_earnings'] as num?)?.toDouble() ?? 0.0,
      thisMonthEarnings:
          (json['this_month_earnings'] as num?)?.toDouble() ?? 0.0,
      thisYearEarnings: (json['this_year_earnings'] as num?)?.toDouble() ?? 0.0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      totalTripsToday: (json['total_trips'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$WalletOverviewModelToJson(
  WalletOverviewModel instance,
) => <String, dynamic>{
  'balance': instance.balance,
  'available_balance': instance.availableBalance,
  'withdrawn': instance.withdrawn,
  'currency': instance.currency,
  'today_earnings': instance.todayEarnings,
  'this_week_earnings': instance.thisWeekEarnings,
  'this_month_earnings': instance.thisMonthEarnings,
  'this_year_earnings': instance.thisYearEarnings,
  'earnings': instance.earnings,
  'total_trips': instance.totalTripsToday,
  'is_verified': instance.isVerified,
  'last_updated': instance.lastUpdated?.toIso8601String(),
};

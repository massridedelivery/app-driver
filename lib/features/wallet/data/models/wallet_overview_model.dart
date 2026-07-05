import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';

part 'wallet_overview_model.g.dart';

/// Data model for GET /api/driver/earnings (typed EarningsSummary, v1.6.0-dev16).
///
/// Two response shapes share `balance, available_balance, withdrawn,
/// total_trips, is_verified`:
///  • no-range → rolling breakdown: `today_earnings, this_week_earnings,
///    this_month_earnings, this_year_earnings` (total_trips = today's count).
///  • ranged (start_date & end_date) → single window: `earnings, range`
///    (total_trips = window count).
/// Shape-specific fields are omitted from the other shape (omitempty), so every
/// field is optional/defaulted — parsing never throws and a genuine 0 renders.
@JsonSerializable(createFactory: true, fieldRename: FieldRename.snake)
class WalletOverviewModel {
  @JsonKey(defaultValue: 0.0)
  final double balance;

  /// Withdrawable cash balance (common field, both shapes).
  @JsonKey(defaultValue: 0.0)
  final double availableBalance;

  @JsonKey(defaultValue: 0.0)
  final double withdrawn;

  @JsonKey(defaultValue: 'THB')
  final String currency;

  // ── no-range (rolling breakdown) ──
  @JsonKey(defaultValue: 0.0)
  final double todayEarnings;
  @JsonKey(defaultValue: 0.0)
  final double thisWeekEarnings;
  @JsonKey(defaultValue: 0.0)
  final double thisMonthEarnings;
  @JsonKey(defaultValue: 0.0)
  final double thisYearEarnings;

  // ── ranged (single window) ──
  /// Period total when start_date & end_date are supplied.
  @JsonKey(defaultValue: 0.0)
  final double earnings;

  /// API field is `total_trips` (today's count in no-range, window count in ranged).
  @JsonKey(name: 'total_trips', defaultValue: 0)
  final int totalTripsToday;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  /// Absent from the API contract → nullable.
  final DateTime? lastUpdated;

  const WalletOverviewModel({
    this.balance = 0.0,
    this.availableBalance = 0.0,
    this.withdrawn = 0.0,
    this.currency = 'THB',
    this.todayEarnings = 0.0,
    this.thisWeekEarnings = 0.0,
    this.thisMonthEarnings = 0.0,
    this.thisYearEarnings = 0.0,
    this.earnings = 0.0,
    this.totalTripsToday = 0,
    this.isVerified = false,
    this.lastUpdated,
  });

  factory WalletOverviewModel.fromJson(Map<String, dynamic> json) =>
      _$WalletOverviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletOverviewModelToJson(this);

  WalletOverview toEntity() {
    return WalletOverview(
      balance: balance,
      availableBalance: availableBalance,
      withdrawn: withdrawn,
      currency: currency,
      todayEarnings: todayEarnings,
      thisWeekEarnings: thisWeekEarnings,
      thisMonthEarnings: thisMonthEarnings,
      thisYearEarnings: thisYearEarnings,
      earnings: earnings,
      totalTripsToday: totalTripsToday,
      isVerified: isVerified,
      lastUpdated: lastUpdated,
    );
  }
}

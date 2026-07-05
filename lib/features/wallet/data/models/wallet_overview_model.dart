import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';

part 'wallet_overview_model.g.dart';

/// Data model for GET /api/driver/earnings response.
///
/// The real response is `{ balance, withdrawn, today_earnings, total_trips,
/// is_verified }` (SCRUM-42 §1). Fields the backend does NOT send (`currency`,
/// `last_updated`) are optional/defaulted so parsing never throws on the real
/// contract — the previous model required them and only survived via mocks.
@JsonSerializable(createFactory: true, fieldRename: FieldRename.snake)
class WalletOverviewModel {
  @JsonKey(defaultValue: 0.0)
  final double balance;

  @JsonKey(defaultValue: 0.0)
  final double withdrawn;

  @JsonKey(defaultValue: 'THB')
  final String currency;

  @JsonKey(defaultValue: 0.0)
  final double todayEarnings;

  /// API field is `total_trips` (not `total_trips_today`).
  @JsonKey(name: 'total_trips', defaultValue: 0)
  final int totalTripsToday;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  /// Absent from the API contract → nullable.
  final DateTime? lastUpdated;

  const WalletOverviewModel({
    this.balance = 0.0,
    this.withdrawn = 0.0,
    this.currency = 'THB',
    this.todayEarnings = 0.0,
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
      withdrawn: withdrawn,
      currency: currency,
      todayEarnings: todayEarnings,
      totalTripsToday: totalTripsToday,
      isVerified: isVerified,
      lastUpdated: lastUpdated,
    );
  }
}

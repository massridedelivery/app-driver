import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';

part 'wallet_overview_model.g.dart';

/// Data model for GET /api/driver/earnings response.
@JsonSerializable(createFactory: true, fieldRename: FieldRename.snake)
class WalletOverviewModel {
  final double balance;
  final String currency;
  final double todayEarnings;
  final int totalTripsToday;
  final bool isVerified;
  final DateTime lastUpdated;

  const WalletOverviewModel({
    required this.balance,
    required this.currency,
    required this.todayEarnings,
    required this.totalTripsToday,
    required this.isVerified,
    required this.lastUpdated,
  });

  factory WalletOverviewModel.fromJson(Map<String, dynamic> json) =>
      _$WalletOverviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletOverviewModelToJson(this);

  WalletOverview toEntity() {
    return WalletOverview(
      balance: balance,
      currency: currency,
      todayEarnings: todayEarnings,
      totalTripsToday: totalTripsToday,
      isVerified: isVerified,
      lastUpdated: lastUpdated,
    );
  }
}

/// Domain entity for the wallet overview screen.
/// Maps from GET /api/driver/earnings response
/// (`{ balance, withdrawn, today_earnings, total_trips, is_verified }`).
class WalletOverview {
  /// Current total wallet balance (can be negative = COD debt).
  final double balance;

  /// Withdrawable cash balance (common field in both API shapes).
  final double availableBalance;

  /// Amount already withdrawn.
  final double withdrawn;

  /// ISO 4217 currency code. Not returned by the API — defaults to "THB".
  final String currency;

  /// Rolling breakdown (no-range shape).
  final double todayEarnings;
  final double thisWeekEarnings;
  final double thisMonthEarnings;
  final double thisYearEarnings;

  /// Period total (ranged shape, when start_date & end_date are supplied).
  final double earnings;

  /// Completed trips (today's count in no-range, window count in ranged).
  final int totalTripsToday;

  /// Whether the driver's KYC/documents are verified (NOT balance confirmation).
  final bool isVerified;

  /// Timestamp of the last balance update. The API does not provide this
  /// (SCRUM-42 Gaps #4); callers may fall back to the client fetch time.
  final DateTime? lastUpdated;

  const WalletOverview({
    required this.balance,
    this.availableBalance = 0.0,
    this.withdrawn = 0.0,
    this.currency = 'THB',
    required this.todayEarnings,
    this.thisWeekEarnings = 0.0,
    this.thisMonthEarnings = 0.0,
    this.thisYearEarnings = 0.0,
    this.earnings = 0.0,
    required this.totalTripsToday,
    required this.isVerified,
    this.lastUpdated,
  });
}

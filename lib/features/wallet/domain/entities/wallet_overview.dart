/// Domain entity for the wallet overview screen.
/// Maps from GET /api/driver/earnings response.
class WalletOverview {
  /// Current wallet balance.
  final double balance;

  /// ISO 4217 currency code (e.g. "THB").
  final String currency;

  /// Total earnings for today.
  final double todayEarnings;

  /// Number of completed trips today.
  final int totalTripsToday;

  /// Whether the driver's bank account is verified.
  final bool isVerified;

  /// Timestamp of the last balance update.
  final DateTime lastUpdated;

  const WalletOverview({
    required this.balance,
    required this.currency,
    required this.todayEarnings,
    required this.totalTripsToday,
    required this.isVerified,
    required this.lastUpdated,
  });
}

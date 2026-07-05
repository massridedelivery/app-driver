/// Domain entity for the wallet overview screen.
/// Maps from GET /api/driver/earnings response
/// (`{ balance, withdrawn, today_earnings, total_trips, is_verified }`).
class WalletOverview {
  /// Current total wallet balance (can be negative = COD debt).
  final double balance;

  /// Amount already withdrawn.
  final double withdrawn;

  /// ISO 4217 currency code. Not returned by the API — defaults to "THB".
  final String currency;

  /// Total earnings for today (or the requested period when date params sent).
  final double todayEarnings;

  /// Number of completed trips.
  final int totalTripsToday;

  /// Whether the driver's KYC/documents are verified (NOT balance confirmation).
  final bool isVerified;

  /// Timestamp of the last balance update. The API does not provide this
  /// (SCRUM-42 Gaps #4); callers may fall back to the client fetch time.
  final DateTime? lastUpdated;

  const WalletOverview({
    required this.balance,
    this.withdrawn = 0.0,
    this.currency = 'THB',
    required this.todayEarnings,
    required this.totalTripsToday,
    required this.isVerified,
    this.lastUpdated,
  });
}

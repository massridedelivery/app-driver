import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';

abstract class WalletOverviewRepository {
  /// Fetches current balance and today's (or a period's) performance metrics.
  /// Corresponds to GET /api/driver/earnings. Pass [startDate]/[endDate]
  /// (YYYY-MM-DD) to get period earnings via `today_earnings`.
  Future<WalletOverview> getWalletOverview({
    String? startDate,
    String? endDate,
  });
}

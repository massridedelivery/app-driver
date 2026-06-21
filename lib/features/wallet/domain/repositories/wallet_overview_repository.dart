import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';

abstract class WalletOverviewRepository {
  /// Fetches current balance and today's performance metrics.
  /// Corresponds to GET /api/driver/earnings
  Future<WalletOverview> getWalletOverview();
}

abstract class WalletOverviewApiService {
  /// Calls GET /api/driver/earnings
  Future<Map<String, dynamic>> getWalletOverview();
}

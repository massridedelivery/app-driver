abstract class WalletOverviewApiService {
  /// Calls GET /api/driver/earnings. When [startDate]/[endDate] (YYYY-MM-DD)
  /// are provided, `today_earnings` in the response is the period total
  /// (SCRUM-42 §1 "รายได้ (period)").
  Future<Map<String, dynamic>> getWalletOverview({
    String? startDate,
    String? endDate,
  });
}

abstract class WalletApiService {
  Future<Map<String, dynamic>> getPayouts();
  Future<Map<String, dynamic>> getPayoutSummary();
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data);
  Future<Map<String, dynamic>> settleDebt(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getPaymentIntent(String intentId);
  Future<Map<String, dynamic>> submitSettlementSlip(String intentId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> getCodStatus();
  Future<Map<String, dynamic>> getTransactions({String? type});
  Future<Map<String, dynamic>> getEarnings();
}

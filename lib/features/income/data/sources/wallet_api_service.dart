abstract class WalletApiService {
  Future<Map<String, dynamic>> getWalletType();
  Future<Map<String, dynamic>> getPayouts();
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data);
  Future<Map<String, dynamic>> topup(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getCodStatus();
  Future<Map<String, dynamic>> getTransactions({String? type});
  Future<Map<String, dynamic>> getEarnings();
}

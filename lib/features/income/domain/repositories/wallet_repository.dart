abstract class WalletRepository {
  Future<Map<String, dynamic>> getPayouts();
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data);
  Future<Map<String, dynamic>> topup(Map<String, dynamic> data);
  Future<Map<String, dynamic>> submitTopupSlip(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getCodStatus();
}

import 'package:massdrive/features/income/domain/entities/wallet_response.dart';

abstract class WalletRepository {
  Future<WalletResponse> getWalletType();
  Future<Map<String, dynamic>> getPayouts();
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data);
  Future<Map<String, dynamic>> topup(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getCodStatus();
}

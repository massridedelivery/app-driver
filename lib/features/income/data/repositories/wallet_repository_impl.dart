import 'package:injectable/injectable.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';
import 'package:massdrive/features/income/domain/repositories/wallet_repository.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  final WalletApiService _apiService;

  WalletRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getPayouts() async {
    return await _apiService.getPayouts();
  }

  @override
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    return await _apiService.requestPayout(data);
  }

  @override
  Future<Map<String, dynamic>> settleDebt(Map<String, dynamic> data) async {
    return await _apiService.settleDebt(data);
  }

  @override
  Future<Map<String, dynamic>> submitSettlementSlip(String intentId, Map<String, dynamic> data) async {
    return await _apiService.submitSettlementSlip(intentId, data);
  }

  @override
  Future<Map<String, dynamic>> getCodStatus() async {
    return await _apiService.getCodStatus();
  }
}

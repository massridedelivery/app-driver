import 'package:injectable/injectable.dart';
import 'package:massdrive/features/income/data/models/wallet_response_model.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';
import 'package:massdrive/features/income/domain/entities/wallet_response.dart';
import 'package:massdrive/features/income/domain/repositories/wallet_repository.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  final WalletApiService _apiService;

  WalletRepositoryImpl(this._apiService);

  @override
  Future<WalletResponse> getWalletType() async {
    final response = await _apiService.getWalletType();
    return WalletResponseModel.fromJson(response).toEntity();
  }
}

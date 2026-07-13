import 'package:injectable/injectable.dart';
import 'package:massdrive/features/wallet/data/models/wallet_overview_model.dart';
import 'package:massdrive/features/wallet/data/sources/wallet_overview_api_service.dart';
import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';
import 'package:massdrive/features/wallet/domain/repositories/wallet_overview_repository.dart';

@LazySingleton(as: WalletOverviewRepository)
class WalletOverviewRepositoryImpl implements WalletOverviewRepository {
  final WalletOverviewApiService _apiService;

  WalletOverviewRepositoryImpl(this._apiService);

  @override
  Future<WalletOverview> getWalletOverview({
    String? startDate,
    String? endDate,
  }) async {
    final json = await _apiService.getWalletOverview(
      startDate: startDate,
      endDate: endDate,
    );
    return WalletOverviewModel.fromJson(json).toEntity();
  }
}

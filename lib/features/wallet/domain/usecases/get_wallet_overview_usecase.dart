import 'package:injectable/injectable.dart';
import 'package:massdrive/features/wallet/domain/entities/wallet_overview.dart';
import 'package:massdrive/features/wallet/domain/repositories/wallet_overview_repository.dart';

@injectable
class GetWalletOverviewUseCase {
  final WalletOverviewRepository _repository;

  GetWalletOverviewUseCase(this._repository);

  Future<WalletOverview> execute() {
    return _repository.getWalletOverview();
  }
}

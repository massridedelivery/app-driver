import 'package:injectable/injectable.dart';
import 'package:massdrive/features/income/domain/entities/wallet_response.dart';
import 'package:massdrive/features/income/domain/repositories/wallet_repository.dart';

@injectable
class GetWalletTypeUseCase {
  final WalletRepository _repository;

  GetWalletTypeUseCase(this._repository);

  Future<WalletResponse> execute() {
    return _repository.getWalletType();
  }
}

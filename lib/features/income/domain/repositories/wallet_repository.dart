import 'package:massdrive/features/income/domain/entities/wallet_response.dart';

abstract class WalletRepository {
  Future<WalletResponse> getWalletType();
}

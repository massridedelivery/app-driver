import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/income/domain/usecase/get_wallet_type_usecase.dart';
import 'package:massdrive/features/income/presentation/states/wallet_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_controller.g.dart';

@riverpod
class WalletController extends _$WalletController {
  @override
  WalletState build() {
    // Initial fetch implicitly calls Future
    Future.microtask(() => fetchWalletData());
    return const WalletState();
  }

  Future<void> fetchWalletData() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final getWalletTypeUseCase = getIt<GetWalletTypeUseCase>();
      final response = await getWalletTypeUseCase.execute();
      
      state = state.copyWith(
        isLoading: false,
        cashBalance: response.cashBalance,
        creditBalance: response.creditBalance,
      );
    } catch (e) {
      debugPrint('WalletController: Error \$e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

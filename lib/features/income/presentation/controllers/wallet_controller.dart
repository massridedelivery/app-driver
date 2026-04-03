import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/income/domain/usecase/get_wallet_type_usecase.dart';
import 'package:massdrive/features/income/presentation/states/wallet_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';

part 'wallet_controller.g.dart';

@riverpod
class WalletController extends _$WalletController {
  @override
  WalletState build() {
    Future.microtask(() => fetchAll());
    return const WalletState();
  }

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      await Future.wait([fetchWalletData(), fetchEarnings()]);
    } catch (e) {
      debugPrint('WalletController: Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchWalletData() async {
    try {
      final getWalletTypeUseCase = getIt<GetWalletTypeUseCase>();
      final response = await getWalletTypeUseCase.execute();

      state = state.copyWith(
        cashBalance: response.cashBalance,
        creditBalance: response.creditBalance,
      );
    } catch (e) {
      debugPrint('WalletController: fetchWalletData Error $e');
    }
  }

  Future<void> fetchEarnings() async {
    try {
      final walletService = getIt<WalletApiService>();
      final data = await walletService.getEarnings();

      state = state.copyWith(
        earningsToday: (data['today'] as num?)?.toDouble() ?? 0.0,
        earningsWeek: (data['this_week'] as num?)?.toDouble() ?? 0.0,
        tripsToday: (data['total_trips_today'] as num?)?.toInt() ?? 0,
        tripsWeek: (data['total_trips_week'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('WalletController: fetchEarnings Error $e');
    }
  }

  Future<void> fetchTransactions({String? type}) async {
    state = state.copyWith(isLoading: true);
    try {
      final walletService = getIt<WalletApiService>();
      final data = await walletService.getTransactions(type: type);
      final list = (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      state = state.copyWith(transactions: list);
    } catch (e) {
      debugPrint('WalletController: fetchTransactions Error $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> requestPayout(double amount) async {
    state = state.copyWith(isLoading: true);
    try {
      final walletService = getIt<WalletApiService>();
      await walletService.requestPayout({'amount': amount});
      await fetchWalletData();
      return true;
    } catch (e) {
      debugPrint('WalletController: requestPayout Error $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Map<String, dynamic>?> topup(double amount) async {
    state = state.copyWith(isLoading: true);
    try {
      final walletService = getIt<WalletApiService>();
      final result = await walletService.topup({'amount': amount});
      await fetchWalletData();
      return result;
    } catch (e) {
      debugPrint('WalletController: topup Error $e');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

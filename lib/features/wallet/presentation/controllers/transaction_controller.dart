import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/usecases/get_transaction_list_usecase.dart';
import 'package:massdrive/features/wallet/presentation/states/transaction_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_controller.g.dart';

@riverpod
class TransactionController extends _$TransactionController {
  @override
  TransactionState build() => const TransactionState();

  /// Loads the first page of transactions.
  /// Call this on screen init with desired filters.
  Future<void> fetchTransactions(TransactionQuery query) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      currentQuery: query,
    );
    try {
      final useCase = getIt<GetTransactionListUseCase>();
      final result = await useCase.execute(query);
      state = state.copyWith(
        isLoading: false,
        transactions: result.transactions,
        total: result.total,
      );
    } catch (e) {
      debugPrint('TransactionController: fetchTransactions Error $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Loads the next page and appends results (infinite scroll).
  Future<void> loadMore() async {
    final hasMore = state.transactions.length < state.total;
    if (state.isLoadingMore || !hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final useCase = getIt<GetTransactionListUseCase>();
      final nextQuery = state.currentQuery.nextPage();
      final result = await useCase.execute(nextQuery);
      state = state.copyWith(
        isLoadingMore: false,
        currentQuery: nextQuery,
        transactions: [...state.transactions, ...result.transactions],
        total: result.total,
      );
    } catch (e) {
      debugPrint('TransactionController: loadMore Error $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Applies a filter and reloads from the first page.
  Future<void> applyFilter({String? type, String? status}) async {
    final newQuery = state.currentQuery.copyWith(
      type: type,
      status: status,
      offset: 0,
    );
    await fetchTransactions(newQuery);
  }
}

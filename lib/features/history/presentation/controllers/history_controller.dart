import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/history/domain/usecases/get_history_list_usecase.dart';
import 'package:massdrive/features/history/presentation/states/history_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_controller.g.dart';

@riverpod
class HistoryController extends _$HistoryController {
  @override
  HistoryState build() => const HistoryState();

  Future<void> fetchHistoryList() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      page: 1,
      hasMore: true,
    );
    try {
      final useCase = getIt<GetHistoryListUseCase>();
      final items = await useCase.execute(page: 1, limit: 20);
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= 20,
      );
    } catch (e) {
      debugPrint('HistoryController: fetchHistoryList Error $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final useCase = getIt<GetHistoryListUseCase>();
      final newItems = await useCase.execute(page: nextPage, limit: 20);
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...newItems],
        page: nextPage,
        hasMore: newItems.length >= 20,
      );
    } catch (e) {
      debugPrint('HistoryController: loadMore Error $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

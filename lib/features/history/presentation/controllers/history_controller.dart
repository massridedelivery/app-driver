import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/history/domain/usecases/get_history_list_usecase.dart';
import 'package:massdrive/features/history/presentation/states/history_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_controller.g.dart';

@riverpod
class HistoryController extends _$HistoryController {
  static const int _pageLimit = 20;

  @override
  HistoryState build() => const HistoryState();

  Future<void> fetchHistoryList({
    String? type,
    bool useCurrentFilter = false,
  }) async {
    final effectiveType = useCurrentFilter ? state.selectedType : type;
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      items: [], // Clear items to prevent stale UI from other tabs
      page: 0,
      hasMore: true,
      selectedType: effectiveType,
    );
    try {
      final useCase = getIt<GetHistoryListUseCase>();
      final items = await useCase.execute(
        limit: _pageLimit,
        offset: 0,
        type: effectiveType,
      );
      state = state.copyWith(
        isLoading: false,
        items: items,
        page: 0,
        hasMore: items.length >= _pageLimit,
      );
    } catch (e, stackTrace) {
      debugPrint('HistoryController: fetchHistoryList Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Set a type filter and reload the list.
  /// Pass null to clear the filter (show all).
  Future<void> setTypeFilter(String? type) async {
    await fetchHistoryList(type: type);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final nextOffset = state.items.length;
    state = state.copyWith(isLoadingMore: true);
    try {
      final useCase = getIt<GetHistoryListUseCase>();
      final newItems = await useCase.execute(
        limit: _pageLimit,
        offset: nextOffset,
        type: state.selectedType,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...newItems],
        page: nextOffset,
        hasMore: newItems.length >= _pageLimit,
      );
    } catch (e) {
      debugPrint('HistoryController: loadMore Error $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

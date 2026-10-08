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

  /// YYYY-MM-DD for the backend start_date/end_date query params.
  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> fetchHistoryList({
    String? type,
    DateTime? date,
    bool useCurrentFilter = false,
  }) async {
    final effectiveType = useCurrentFilter ? state.selectedType : type;
    final effectiveDate = useCurrentFilter ? state.selectedDate : date;
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      items: [], // Clear items to prevent stale UI from other tabs
      page: 0,
      hasMore: true,
      selectedType: effectiveType,
      selectedDate: effectiveDate,
    );
    try {
      final useCase = getIt<GetHistoryListUseCase>();
      final dateStr = effectiveDate != null ? _fmtDate(effectiveDate) : null;
      final items = await useCase.execute(
        limit: _pageLimit,
        offset: 0,
        type: effectiveType,
        startDate: dateStr,
        endDate: dateStr,
      );
      state = state.copyWith(
        isLoading: false,
        items: items,
        page: 0,
        hasMore: items.length >= _pageLimit,
      );
    } catch (e) {
      debugPrint('HistoryController: fetchHistoryList Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Set a type filter and reload (keeps the current date filter).
  /// Pass null to clear the filter (show all).
  Future<void> setTypeFilter(String? type) async {
    await fetchHistoryList(type: type, date: state.selectedDate);
  }

  /// Set a date filter and reload (keeps the current type filter).
  /// Pass null to clear the date filter (show all dates).
  Future<void> setDateFilter(DateTime? date) async {
    await fetchHistoryList(type: state.selectedType, date: date);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final nextOffset = state.items.length;
    state = state.copyWith(isLoadingMore: true);
    try {
      final useCase = getIt<GetHistoryListUseCase>();
      final dateStr =
          state.selectedDate != null ? _fmtDate(state.selectedDate!) : null;
      final newItems = await useCase.execute(
        limit: _pageLimit,
        offset: nextOffset,
        type: state.selectedType,
        startDate: dateStr,
        endDate: dateStr,
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

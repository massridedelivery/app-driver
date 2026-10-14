import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/history/domain/usecases/get_history_list_usecase.dart';
import 'package:massdrive/features/history/presentation/states/history_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_controller.g.dart';

@riverpod
class HistoryController extends _$HistoryController {
  static const int _pageLimit = 20;

  /// A page can be all top-ups (filtered out); keep reading a few more pages
  /// so the list isn't empty while trips exist further back.
  static const int _maxPagesPerLoad = 5;

  /// job id → vehicle type, for the row icons. Loaded once per screen.
  Map<String, String>? _vehicleByJob;

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
      final dateStr = effectiveDate != null ? _fmtDate(effectiveDate) : null;
      final page = await _loadTripRows(
        offset: 0,
        type: effectiveType,
        date: dateStr,
      );
      state = state.copyWith(
        isLoading: false,
        items: page.rows,
        page: page.nextOffset,
        hasMore: page.hasMore,
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
    state = state.copyWith(isLoadingMore: true);
    try {
      final dateStr =
          state.selectedDate != null ? _fmtDate(state.selectedDate!) : null;
      final page = await _loadTripRows(
        offset: state.page,
        type: state.selectedType,
        date: dateStr,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.rows],
        page: page.nextOffset,
        hasMore: page.hasMore,
      );
    } catch (e) {
      debugPrint('HistoryController: loadMore Error $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Reads transaction pages from [offset] until at least one trip row turns
  /// up (or the API runs out). `nextOffset` counts raw API rows — `page` in
  /// the state — since filtered rows can't be used as an offset.
  Future<({List<HistoryItemModel> rows, int nextOffset, bool hasMore})>
  _loadTripRows({required int offset, String? type, String? date}) async {
    final useCase = getIt<GetHistoryListUseCase>();
    final vehicles = await _vehicleTypes();
    final rows = <HistoryItemModel>[];
    var next = offset;
    var hasMore = true;
    for (var i = 0; i < _maxPagesPerLoad && hasMore && rows.isEmpty; i++) {
      final raw = await useCase.execute(
        limit: _pageLimit,
        offset: next,
        type: type,
        startDate: date,
        endDate: date,
      );
      next += raw.length;
      hasMore = raw.length >= _pageLimit;
      rows.addAll(tripRows(raw, vehicles));
    }
    return (rows: rows, nextOffset: next, hasMore: hasMore);
  }

  /// Best effort: without it the rows just show the generic ride icon.
  Future<Map<String, String>> _vehicleTypes() async {
    final cached = _vehicleByJob;
    if (cached != null) return cached;
    try {
      final res = await getIt<Dio>().get(
        Endpoints.driverEarningsTrips,
        queryParameters: {'limit': 100},
      );
      return _vehicleByJob = vehicleTypesByJob(res.data);
    } catch (e) {
      debugPrint('HistoryController: vehicle types unavailable $e');
      return const {};
    }
  }
}

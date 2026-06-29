import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/history_item_model.dart';

part 'history_state.freezed.dart';

@freezed
sealed class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default([]) List<HistoryItemModel> items,
    @Default('') String errorMessage,
    @Default(0) int page,
    @Default(true) bool hasMore,
    String? selectedType, // null = all, e.g. 'FARE_PAYMENT'
  }) = _HistoryState;
}

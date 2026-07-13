import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';

part 'transaction_state.freezed.dart';

@freezed
sealed class TransactionState with _$TransactionState {
  const factory TransactionState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default([]) List<Transaction> transactions,
    @Default(0) int total,
    @Default('') String errorMessage,
    @Default(TransactionQuery()) TransactionQuery currentQuery,
  }) = _TransactionState;
}

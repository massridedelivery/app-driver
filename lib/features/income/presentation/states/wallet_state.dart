import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_state.freezed.dart';

@freezed
sealed class WalletState with _$WalletState {
  const factory WalletState({
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default(0.0) double cashBalance,
    @Default(0.0) double creditBalance,
    @Default(0.0) double earningsToday,
    @Default(0.0) double earningsWeek,
    @Default(0) int tripsToday,
    @Default(0) int tripsWeek,
    @Default([]) List<Map<String, dynamic>> transactions,
  }) = _WalletState;
}

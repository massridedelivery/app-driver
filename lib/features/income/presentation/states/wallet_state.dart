import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_state.freezed.dart';

@freezed
sealed class WalletState with _$WalletState {
  const factory WalletState({
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default('0') String cashBalance,
    @Default('0') String creditBalance,
  }) = _WalletState;
}

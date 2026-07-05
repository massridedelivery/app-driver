import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:massdrive/features/document_registration/domain/models/bank_account_info.dart';

part 'wallet_state.freezed.dart';

@freezed
sealed class WalletState with _$WalletState {
  const factory WalletState({
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default(0.0) double balance,
    @Default('THB') String currency,
    @Default(false) bool isVerified,
    DateTime? lastUpdated,
    // Earnings & trips
    @Default(0.0) double earningsToday,
    @Default(0.0) double earningsWeek,
    @Default(0) int tripsToday,
    @Default(0) int totalTripsToday,
    @Default(0) int tripsWeek,
    @Default(0.0) double codDebt,
    @Default(0.0) double currentBalance,
    @Default(-500.0) double codThreshold,
    // Dual-wallet split from GET /api/driver/payouts/summary (SCRUM-42).
    // Cash = withdrawable earnings; Credit = non-withdrawable COD top-up credit.
    @Default(0.0) double cashBalance,
    @Default(0.0) double creditBalance,
    @Default([]) List<Map<String, dynamic>> transactions,
    BankAccountInfo? bankAccountInfo,
  }) = _WalletState;
}

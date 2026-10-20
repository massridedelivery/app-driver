import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:massdrive/features/document_registration/domain/models/bank_account_info.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';

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
    @Default(0.0) double earningsMonth,
    @Default(0.0) double earningsYear,
    @Default(0) int tripsToday,
    @Default(0) int totalTripsToday,
    @Default(0) int tripsWeek,
    // Dual-wallet split from GET /api/driver/payouts/summary (SCRUM-42).
    // Cash = withdrawable earnings; Credit = non-withdrawable COD top-up credit.
    @Default(0.0) double cashBalance,
    @Default(0.0) double creditBalance,
    @Default([]) List<Map<String, dynamic>> transactions,
    // Total transaction count from GET /api/driver/earnings/transactions `total`
    // (SCRUM-42) — the full count, not just the loaded page length.
    @Default(0) int transactionsTotal,
    BankAccountInfo? bankAccountInfo,
    // Withdrawal rules from GET /api/driver/payouts/summary.
    @Default(PayoutLimits()) PayoutLimits payoutLimits,
    // Cash-job gate from the same summary (BE dev115); null until loaded.
    CashJobGate? cashJobGate,
    // MANUAL top-up refused with 400 (company receiving account not set):
    // the credit wallet hides "โอนเงินเข้าบัญชี" and points to PromptPay.
    @Default(false) bool manualTopupUnavailable,
  }) = _WalletState;
}

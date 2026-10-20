import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/income/domain/models/topup.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/document_registration/data/sources/media_api_service.dart';
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart';
import 'package:massdrive/features/income/domain/repositories/wallet_repository.dart';
import 'package:massdrive/features/income/presentation/states/wallet_state.dart';
import 'package:massdrive/features/wallet/domain/usecases/get_wallet_overview_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';
import 'package:massdrive/core/auth/session_notifier.dart';

part 'wallet_controller.g.dart';

@Riverpod(keepAlive: true)
class WalletController extends _$WalletController {
  @override
  WalletState build() {
    Future.microtask(() => fetchAll());
    // A slip was approved/rejected (topup_* push): balances and COD status
    // changed server-side, so reload them.
    void onTopupChanged() => fetchAll();
    TopupUpdates.instance.addListener(onTopupChanged);
    ref.onDispose(() => TopupUpdates.instance.removeListener(onTopupChanged));
    // keepAlive outlives a logout: start clean on every login / logout so the
    // next driver never sees the previous one's totals.
    void onSessionChanged() => ref.invalidateSelf();
    SessionNotifier.instance.addListener(onSessionChanged);
    ref.onDispose(
      () => SessionNotifier.instance.removeListener(onSessionChanged),
    );
    return const WalletState();
  }

  /// [silent] refreshes in place (no full-screen loader) when figures are
  /// already on screen.
  Future<void> fetchAll({bool silent = false}) async {
    state = state.copyWith(isLoading: !silent, errorMessage: '');
    try {
      await fetchEarnings();
      await fetchTransactionSummary();
      await fetchPayoutMethod();
    } catch (e) {
      debugPrint('WalletController: Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchEarnings() async {
    try {
      final useCase = getIt<GetWalletOverviewUseCase>();
      final overview = await useCase.execute();

      // The gross figures (SCRUM-67) are the real money the driver took in
      // (fares + bonuses, never negative), computed server-side. The net
      // *_earnings fields still net commission/COD and can go negative, so
      // the headline uses gross — including for the year, which the old
      // client-side ledger workaround couldn't cover.
      state = state.copyWith(
        balance: overview.balance,
        currency: overview.currency,
        isVerified: overview.isVerified,
        // API has no last_updated (SCRUM-42 Gaps #4) — fall back to fetch time.
        lastUpdated: overview.lastUpdated ?? DateTime.now(),
        // Rolling breakdown comes in the single no-range earnings response
        // (v1.6.0-dev16) — no separate ranged call needed.
        // What the driver really earned (after commission) — a ฿44 fare at
        // 7 commission reads ฿37, not ฿44. Gross only if the BE predates
        // the *_income fields.
        earningsToday: overview.todayIncome ?? overview.todayGrossEarnings,
        earningsWeek: overview.thisWeekIncome ?? overview.thisWeekGrossEarnings,
        earningsMonth:
            overview.thisMonthIncome ?? overview.thisMonthGrossEarnings,
        earningsYear: overview.thisYearIncome ?? overview.thisYearGrossEarnings,
        totalTripsToday: overview.totalTripsToday,
        // A previous failure is resolved — clear it so the screen leaves the
        // error state.
        errorMessage: '',
      );

      await fetchPayoutSummary();
    } catch (e) {
      debugPrint('WalletController: fetchEarnings Error $e');
      // This is the screen's primary data. Swallowing the failure leaves the
      // driver looking at zeros with no idea the fetch never landed.
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Cash vs Credit wallet split (SCRUM-42 §2, GET /api/driver/payouts/summary).
  /// Cash = `available_balance` (withdrawable); Credit = `credit_balance`.
  /// Also the cash-job gate (BE dev115): returns it, or null when the fetch
  /// failed (the last known gate stays in state).
  Future<CashJobGate?> fetchPayoutSummary() async {
    try {
      final walletRepo = getIt<WalletRepository>();
      final summary = await walletRepo.getPayoutSummary();
      final cash = (summary['available_balance'] as num?)?.toDouble() ?? 0.0;
      final credit = (summary['credit_balance'] as num?)?.toDouble() ?? 0.0;
      final gate = CashJobGate.fromSummary(summary);
      state = state.copyWith(
        cashBalance: cash,
        creditBalance: credit,
        payoutLimits: PayoutLimits.fromSummary(summary),
        cashJobGate: gate,
      );
      return gate;
    } catch (e) {
      debugPrint('WalletController: fetchPayoutSummary Error $e');
      return null;
    }
  }

  Future<void> fetchTransactions({String? type}) async {
    state = state.copyWith(isLoading: true);
    try {
      final walletService = getIt<WalletApiService>();
      final data = await walletService.getTransactions(type: type);
      final list = (data['transactions'] as List?)?.cast<Map<String, dynamic>>()
          ?? (data['data'] as List?)?.cast<Map<String, dynamic>>()
          ?? [];
      final total = (data['total'] as num?)?.toInt() ?? list.length;
      state = state.copyWith(transactions: list, transactionsTotal: total);
    } catch (e) {
      debugPrint('WalletController: fetchTransactions Error $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Lightweight fetch of just the transaction `total` for the Earnings screen
  /// (SCRUM-42 "รายการทั้งหมด"), without toggling the screen loading state.
  Future<void> fetchTransactionSummary() async {
    try {
      final walletService = getIt<WalletApiService>();
      final data = await walletService.getTransactions();
      final total = (data['total'] as num?)?.toInt()
          ?? (data['transactions'] as List?)?.length
          ?? 0;
      state = state.copyWith(transactionsTotal: total);
    } catch (e) {
      debugPrint('WalletController: fetchTransactionSummary Error $e');
    }
  }

  Future<void> fetchPayoutMethod() async {
    try {
      final repo = getIt<DocumentRegistrationRepository>();
      final bankInfo = await repo.fetchPayoutMethod();
      state = state.copyWith(bankAccountInfo: bankInfo);
    } catch (e) {
      debugPrint('WalletController: fetchPayoutMethod Error $e');
    }
  }


  /// Request a withdrawal. The backend always pays the admin-approved payout
  /// account and ignores any method in the body, so only the amount is sent.
  /// Returns null on success, or the refusal (branch on [PayoutException.code]).
  /// Sends the request; returns the receipt (wht / net the backend recorded)
  /// or the refusal. The summary is reloaded either way (limits, balance).
  Future<({PayoutReceipt? receipt, PayoutException? error})> requestPayout(
    double amount,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final walletRepo = getIt<WalletRepository>();
      final res = await walletRepo.requestPayout({'amount': amount});
      await fetchEarnings();
      return (receipt: PayoutReceipt.fromJson(res), error: null);
    } on PayoutException catch (e) {
      debugPrint('WalletController: requestPayout refused ${e.code}');
      state = state.copyWith(errorMessage: e.message);
      // A refusal can mean the summary is stale (limit hit, pending request).
      await fetchPayoutSummary();
      return (receipt: null, error: e);
    } catch (e) {
      debugPrint('WalletController: requestPayout Error $e');
      const err = PayoutException(null, null);
      state = state.copyWith(errorMessage: err.message);
      return (receipt: null, error: err);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Withdrawal requests, newest first (GET /api/driver/payouts).
  Future<List<PayoutRecord>> fetchPayoutHistory() async {
    final walletRepo = getIt<WalletRepository>();
    final res = await walletRepo.getPayouts();
    final raw = res['payouts'] ?? res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => PayoutRecord.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Map<String, dynamic>?> settleDebt({
    required double amount,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final walletService = getIt<WalletApiService>();
      final result = await walletService.settleDebt({
        'amount': amount,
        'payment_method': paymentMethod,
      });
      await fetchEarnings();
      return result;
    } on ManualTopupUnavailable catch (e) {
      // The company hasn't set its receiving account: hide MANUAL for now.
      state = state.copyWith(
        manualTopupUnavailable: true,
        errorMessage: friendlyErrorMessage(e),
      );
      return null;
    } catch (e) {
      debugPrint('WalletController: settleDebt Error $e');
      state = state.copyWith(errorMessage: friendlyErrorMessage(e));
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Poll a payment intent's status (SCRUM-35 §2.2 / §4.3).
  /// Returns the raw intent map (`{ id, status, paid_at, ... }`) or null on error.
  Future<Map<String, dynamic>?> getPaymentIntent(String intentId) async {
    try {
      final walletRepo = getIt<WalletRepository>();
      return await walletRepo.getPaymentIntent(intentId);
    } catch (e) {
      debugPrint('WalletController: getPaymentIntent Error $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitSettlementSlip({
    required String intentId,
    required File slipFile,
    required String bankAccountName,
    required DateTime transferAt,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final ext = slipFile.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'webp') contentType = 'image/webp';
      if (ext == 'pdf') contentType = 'application/pdf';

      final mediaService = getIt<MediaApiService>();
      final requestUrlResponse = await mediaService.getUploadUrl({
        'category': 'driver_doc',
        'content_type': contentType,
      });

      final uploadUrlData = requestUrlResponse.data as Map<String, dynamic>;
      final String uploadUrl = uploadUrlData['upload_url'] as String;
      final String fileKey = uploadUrlData['file_key'] as String;

      final fileBytes = await slipFile.readAsBytes();
      await mediaService.uploadFileDirectly(uploadUrl, fileBytes, contentType);

      final dio = getIt<Dio>();
      final confirmResponse = await dio.post(
        Endpoints.mediaConfirm,
        data: {'file_key': fileKey},
      );
      final confirmData = confirmResponse.data as Map<String, dynamic>;
      final bool confirmed = confirmData['confirmed'] as bool? ?? false;
      if (!confirmed) {
        throw Exception('Media confirmation failed');
      }

      final walletRepo = getIt<WalletRepository>();
      final transferAtIso = transferAt.toUtc().toIso8601String();
      final result = await walletRepo.submitSettlementSlip(intentId, {
        'slip_image_key': fileKey,
        'bank_account_name': bankAccountName,
        'transfer_at': transferAtIso,
      });

      await fetchEarnings();
      return result;
    } catch (e) {
      debugPrint('WalletController: submitSettlementSlip Error $e');
      state = state.copyWith(errorMessage: friendlyErrorMessage(e));
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Submitted MANUAL slips with their review status, newest first
  /// (GET /api/driver/settle-debt/requests).
  Future<List<TopupRequest>> fetchTopupRequests() async {
    final res = await getIt<WalletApiService>().getSettlementRequests();
    final raw = res['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => TopupRequest.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

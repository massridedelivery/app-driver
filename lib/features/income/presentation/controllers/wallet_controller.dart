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

part 'wallet_controller.g.dart';

/// Per-service minimum credit (e.g. Standard Bike ฿30, Saver Bike ฿30).
class ServiceMinimum {
  final String name;
  final double min;
  const ServiceMinimum(this.name, this.min);
}

/// Credit-gate status from `GET /api/driver/payouts/summary` (SCRUM-97 / dev16).
/// The backend is the source of truth for the numbers (balance, thresholds,
/// block flag); the warning COPY is composed locally in Thai (SCRUM-97 follow-
/// up — the client owns the wording so it is always Thai and shows the live
/// balance + per-service minimums).
class CreditStatus {
  /// Current credit; can be negative (commission pushed it below zero).
  final double balance;

  /// false when the backend won't dispatch (balance <= 0). Defaults to true so
  /// a missing field never blocks the driver.
  final bool canReceiveJobs;

  /// Warn threshold (default 25, admin-configurable).
  final double minBalanceRequired;

  /// "INSUFFICIENT_CREDIT" (=0) | "NEGATIVE_CREDIT" (<0) | null (healthy).
  final String? reason;

  /// Per-service minimums for the top-up hint; empty → use [minBalanceRequired].
  final List<ServiceMinimum> serviceMinimums;

  const CreditStatus({
    required this.balance,
    required this.canReceiveJobs,
    required this.minBalanceRequired,
    this.reason,
    this.serviceMinimums = const [],
  });
}

@Riverpod(keepAlive: true)
class WalletController extends _$WalletController {
  @override
  WalletState build() {
    Future.microtask(() => fetchAll());
    return const WalletState();
  }

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
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
        currentBalance: overview.balance,
        currency: overview.currency,
        isVerified: overview.isVerified,
        // API has no last_updated (SCRUM-42 Gaps #4) — fall back to fetch time.
        lastUpdated: overview.lastUpdated ?? DateTime.now(),
        // Rolling breakdown comes in the single no-range earnings response
        // (v1.6.0-dev16) — no separate ranged call needed.
        earningsToday: overview.todayGrossEarnings,
        earningsWeek: overview.thisWeekGrossEarnings,
        earningsMonth: overview.thisMonthGrossEarnings,
        earningsYear: overview.thisYearGrossEarnings,
        totalTripsToday: overview.totalTripsToday,
        // A previous failure is resolved — clear it so the screen leaves the
        // error state.
        errorMessage: '',
      );

      await fetchPayoutSummary();
      await fetchCodStatus();
    } catch (e) {
      debugPrint('WalletController: fetchEarnings Error $e');
      // This is the screen's primary data. Swallowing the failure leaves the
      // driver looking at zeros with no idea the fetch never landed.
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Cash vs Credit wallet split (SCRUM-42 §2, GET /api/driver/payouts/summary).
  /// Cash = `available_balance` (withdrawable); Credit = `credit_balance`.
  Future<void> fetchPayoutSummary() async {
    try {
      final walletRepo = getIt<WalletRepository>();
      final summary = await walletRepo.getPayoutSummary();
      final cash = (summary['available_balance'] as num?)?.toDouble() ?? 0.0;
      final credit = (summary['credit_balance'] as num?)?.toDouble() ?? 0.0;
      state = state.copyWith(cashBalance: cash, creditBalance: credit);
    } catch (e) {
      debugPrint('WalletController: fetchPayoutSummary Error $e');
    }
  }

  /// Fetch the credit-gate status (SCRUM-97 / dev16) from the same
  /// payouts/summary payload, and refresh the cash/credit balances in state.
  /// Used by the go-online low-credit dialog.
  Future<CreditStatus> fetchCreditStatus() async {
    final walletRepo = getIt<WalletRepository>();
    final summary = await walletRepo.getPayoutSummary();
    final cash = (summary['available_balance'] as num?)?.toDouble() ?? 0.0;
    final credit = (summary['credit_balance'] as num?)?.toDouble() ?? 0.0;
    state = state.copyWith(cashBalance: cash, creditBalance: credit);
    // Per-service minimums (e.g. Standard Bike / Saver Bike). Tolerant of a few
    // key spellings the backend might use.
    final mins = <ServiceMinimum>[];
    final rawMins = summary['service_minimums'];
    if (rawMins is List) {
      for (final e in rawMins) {
        if (e is Map) {
          final name = (e['service'] ?? e['name'] ?? e['label'])?.toString();
          final m = e['min'] ?? e['min_balance'] ?? e['minimum'];
          if (name != null && name.isNotEmpty && m is num) {
            mins.add(ServiceMinimum(name, m.toDouble()));
          }
        }
      }
    }
    return CreditStatus(
      balance: credit,
      canReceiveJobs: (summary['can_receive_jobs'] as bool?) ?? true,
      minBalanceRequired:
          (summary['min_balance_required'] as num?)?.toDouble() ?? 25.0,
      reason: summary['reason']?.toString(),
      serviceMinimums: mins,
    );
  }

  Future<void> fetchCodStatus() async {
    try {
      final walletRepo = getIt<WalletRepository>();
      final codStatus = await walletRepo.getCodStatus();
      final codDebt = (codStatus['cod_debt'] as num?)?.toDouble() ?? 0.0;
      final currentBalance = (codStatus['current_balance'] as num?)?.toDouble() ?? 0.0;
      final codThreshold = (codStatus['cod_threshold'] as num?)?.toDouble() ?? -500.0;
      state = state.copyWith(
        codDebt: codDebt,
        currentBalance: currentBalance,
        codThreshold: codThreshold,
      );
    } catch (e) {
      debugPrint('WalletController: fetchCodStatus Error $e');
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

  String _mapBankToCode(String bankName) {
    final clean = bankName.toLowerCase();
    if (clean.contains('kbank') || clean.contains('kasikorn') || clean.contains('กสิกร')) {
      return '002';
    } else if (clean.contains('scb') || clean.contains('ไทยพาณิชย์')) {
      return '014';
    } else if (clean.contains('bbl') || clean.contains('กรุงเทพ')) {
      return '002';
    } else if (clean.contains('krung') || clean.contains('ktb') || clean.contains('กรุงไทย')) {
      return '006';
    } else if (clean.contains('ayudhya') || clean.contains('bay') || clean.contains('กรุงศรี')) {
      return '025';
    }
    return '002';
  }

  Future<bool> requestPayout(double amount) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      var bankInfo = state.bankAccountInfo;
      if (bankInfo == null) {
        final repo = getIt<DocumentRegistrationRepository>();
        bankInfo = await repo.fetchPayoutMethod();
        if (bankInfo == null) {
          throw Exception('กรุณาผูกบัญชีธนาคารสำหรับรับเงินก่อนดำเนินการถอน');
        }
        state = state.copyWith(bankAccountInfo: bankInfo);
      }

      final bankCode = _mapBankToCode(bankInfo.bankName);
      final walletRepo = getIt<WalletRepository>();
      await walletRepo.requestPayout({
        'amount': amount,
        'method': {
          'type': 'bank_transfer',
          'details': {
            'bank_name': bankCode,
            'account_number': bankInfo.accountNumber,
            'account_name': bankInfo.accountName,
          },
        },
      });

      await fetchEarnings();
      return true;
    } catch (e) {
      debugPrint('WalletController: requestPayout Error $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
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
    } catch (e) {
      debugPrint('WalletController: settleDebt Error $e');
      state = state.copyWith(errorMessage: e.toString());
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
      state = state.copyWith(errorMessage: e.toString());
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

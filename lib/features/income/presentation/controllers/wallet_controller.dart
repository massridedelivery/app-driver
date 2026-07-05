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

      state = state.copyWith(
        balance: overview.balance,
        currentBalance: overview.balance,
        currency: overview.currency,
        isVerified: overview.isVerified,
        // API has no last_updated (SCRUM-42 Gaps #4) — fall back to fetch time.
        lastUpdated: overview.lastUpdated ?? DateTime.now(),
        earningsToday: overview.todayEarnings,
        totalTripsToday: overview.totalTripsToday,
      );

      await fetchPayoutSummary();
      await fetchCodStatus();
    } catch (e) {
      debugPrint('WalletController: fetchEarnings Error $e');
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
      state = state.copyWith(transactions: list);
    } catch (e) {
      debugPrint('WalletController: fetchTransactions Error $e');
    } finally {
      state = state.copyWith(isLoading: false);
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

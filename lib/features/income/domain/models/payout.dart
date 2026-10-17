import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/utils/baht.dart';

/// Withdrawal rules from `GET /api/driver/payouts/summary`. The defaults are
/// the backend's current values, used only until a summary that carries them
/// has loaded.
@immutable
class PayoutLimits {
  final double minWithdraw;
  final double maxWithdraw;
  final int maxPerDay;
  final int withdrawalsToday;

  /// Withholding tax on a withdrawal, from the summary only (0 since the
  /// backend stopped withholding; never assumed).
  final double whtRate;

  /// Null when the summary didn't say (older backend) — don't block on it.
  final bool? hasPayoutMethod;
  final bool payoutMethodPending;

  const PayoutLimits({
    // An amount must be MORE than this (0 = any positive amount).
    this.minWithdraw = 0,
    this.maxWithdraw = 50000,
    this.maxPerDay = 3,
    this.withdrawalsToday = 0,
    this.whtRate = 0,
    this.hasPayoutMethod,
    this.payoutMethodPending = false,
  });

  factory PayoutLimits.fromSummary(Map<String, dynamic> s) {
    double? d(String k) => (s[k] as num?)?.toDouble();
    int? i(String k) => (s[k] as num?)?.toInt();
    const fallback = PayoutLimits();
    return PayoutLimits(
      minWithdraw: d('min_withdraw') ?? fallback.minWithdraw,
      maxWithdraw: d('max_withdraw') ?? fallback.maxWithdraw,
      maxPerDay: i('max_per_day') ?? fallback.maxPerDay,
      withdrawalsToday: i('withdrawals_today') ?? 0,
      whtRate: d('wht_rate') ?? fallback.whtRate,
      hasPayoutMethod: s['has_payout_method'] as bool?,
      payoutMethodPending: s['payout_method_pending'] as bool? ?? false,
    );
  }

  bool get dailyLimitReached => withdrawalsToday >= maxPerDay;

  /// Withdrawals still allowed today (Thai day, counted by the backend).
  int get remainingToday =>
      (maxPerDay - withdrawalsToday).clamp(0, maxPerDay).toInt();

  /// Why [amount] can't be requested, or null when it can: more than
  /// [minWithdraw], at most [maxWithdraw] and the withdrawable balance, and
  /// no more than 2 decimals.
  String? amountError(double? amount, {required double availableBalance}) {
    if (amount == null || amount <= minWithdraw) {
      return 'กรุณาใส่จำนวนเงินมากกว่า ${formatBahtNumber(minWithdraw)}';
    }
    if (((amount * 100).round() - amount * 100).abs() > 1e-6) {
      return 'ใส่ทศนิยมได้ไม่เกิน 2 ตำแหน่ง';
    }
    if (amount > maxWithdraw) {
      return 'ถอนได้สูงสุด ${formatBaht(maxWithdraw)} ต่อครั้ง';
    }
    if (amount > availableBalance) return 'ยอดเงินไม่เพียงพอ';
    return null;
  }

  /// Tax withheld on [amount], rounded to the satang exactly like the
  /// backend (`round(amount × rate × 100) / 100`).
  double whtFor(double amount) => (amount * whtRate * 100).round() / 100;

  /// What the driver receives for [amount]: amount − [whtFor], so the
  /// breakdown rows always add up.
  double netFor(double amount) => amount - whtFor(amount);

  /// Why a withdrawal can't be requested right now (shown instead of letting
  /// the API refuse it), or null when it can.
  String? blockReason({required double availableBalance}) {
    if (hasPayoutMethod == false) {
      return 'กรุณาเพิ่มบัญชีธนาคารสำหรับรับเงินก่อนถอนเงิน';
    }
    if (payoutMethodPending) {
      return 'บัญชีรับเงินอยู่ระหว่างตรวจสอบ ถอนเงินได้เมื่อบัญชีผ่านการอนุมัติ';
    }
    if (dailyLimitReached) {
      return 'ครบ $maxPerDay ครั้งแล้ววันนี้ ถอนได้อีกครั้งพรุ่งนี้';
    }
    if (availableBalance <= minWithdraw) return 'ยังไม่มียอดที่ถอนได้';
    return null;
  }
}

/// Payout lifecycle: pending → approved → processing → completed, or it ends
/// rejected (not approved) / failed (transfer failed; money stays in wallet).
enum PayoutStatus {
  pending,
  approved,
  processing,
  completed,
  rejected,
  failed,
  unknown;

  static PayoutStatus parse(String? raw) => switch (raw?.toLowerCase()) {
    'pending' => PayoutStatus.pending,
    'approved' => PayoutStatus.approved,
    'processing' => PayoutStatus.processing,
    'completed' => PayoutStatus.completed,
    'rejected' => PayoutStatus.rejected,
    'failed' => PayoutStatus.failed,
    _ => PayoutStatus.unknown,
  };

  String get label => switch (this) {
    PayoutStatus.pending => 'รออนุมัติ',
    PayoutStatus.approved => 'อนุมัติแล้ว',
    PayoutStatus.processing => 'กำลังโอน',
    PayoutStatus.completed => 'โอนสำเร็จ',
    PayoutStatus.rejected => 'ไม่อนุมัติ',
    PayoutStatus.failed => 'โอนไม่สำเร็จ',
    PayoutStatus.unknown => 'ไม่ทราบสถานะ',
  };

  bool get isFinal =>
      this == PayoutStatus.completed ||
      this == PayoutStatus.rejected ||
      this == PayoutStatus.failed;
}

/// One withdrawal request from `GET /api/driver/payouts`.
@immutable
class PayoutRecord {
  final String id;
  final double amount;
  final PayoutStatus status;
  final DateTime? createdAt;
  final DateTime? processedAt;

  /// Written by the company for the driver (rejected / failed). Shown as-is.
  final String? reason;
  final String? bankName;
  final String? accountNumber;

  /// Tax withheld and what reached the bank, as recorded by the backend when
  /// the request was made. Shown as-is — never recomputed from wht_rate.
  final double? whtAmount;
  final double? netAmount;

  const PayoutRecord({
    required this.id,
    required this.amount,
    required this.status,
    this.createdAt,
    this.processedAt,
    this.reason,
    this.bankName,
    this.accountNumber,
    this.whtAmount,
    this.netAmount,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> j) {
    final details = j['method_details'] is Map
        ? Map<String, dynamic>.from(j['method_details'] as Map)
        : const <String, dynamic>{};
    final status = PayoutStatus.parse(j['status']?.toString());
    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return PayoutRecord(
      id: j['id']?.toString() ?? '',
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      status: status,
      createdAt: DateTime.tryParse(
        j['created_at']?.toString() ?? '',
      )?.toLocal(),
      processedAt: DateTime.tryParse(
        j['processed_at']?.toString() ?? '',
      )?.toLocal(),
      reason: status == PayoutStatus.failed
          ? text(j['failure_reason']) ?? text(j['rejection_reason'])
          : text(j['rejection_reason']) ?? text(j['failure_reason']),
      bankName:
          text(details['bank_display_name']) ?? text(details['bank_name']),
      accountNumber: text(details['account_number']),
      whtAmount: (j['wht_amount'] as num?)?.toDouble(),
      netAmount: (j['net_amount'] as num?)?.toDouble(),
    );
  }

  /// Masked account number, e.g. "xxxxxx4521".
  String? get maskedAccount {
    final a = accountNumber;
    if (a == null || a.length < 4) return a;
    return 'xxxxxx${a.substring(a.length - 4)}';
  }
}

/// A withdrawal the backend refused, carrying its machine-readable `code`.
class PayoutException implements Exception {
  const PayoutException(this.code, this.serverMessage);

  final String? code;
  final String? serverMessage;

  factory PayoutException.from(DioException e) {
    final data = e.response?.data;
    String? read(String k) => data is Map ? data[k]?.toString() : null;
    return PayoutException(read('code'), read('error') ?? read('message'));
  }

  /// Thai message for the driver, chosen by code (never by the English text).
  String get message => switch (code) {
    'payout_below_min' => 'กรุณาใส่จำนวนเงินมากกว่า 0',
    'payout_above_max' => 'ถอนได้สูงสุด 50,000 บาทต่อครั้ง',
    // 429 — never retried automatically.
    'payout_limit_exceeded' => 'ถอนครบ 3 ครั้งแล้ววันนี้',
    'insufficient_balance' => 'ยอดเงินที่ถอนได้ไม่พอ',
    'payout_pending_exists' =>
      'มีคำขอถอนที่รอดำเนินการอยู่ รอให้เสร็จก่อนถอนใหม่',
    'no_payout_method' => 'กรุณาเพิ่มบัญชีธนาคารสำหรับรับเงินก่อนถอนเงิน',
    'payout_method_pending' =>
      'บัญชีรับเงินอยู่ระหว่างตรวจสอบ ถอนเงินได้เมื่อบัญชีผ่านการอนุมัติ',
    'unknown_bank' || 'invalid_payout_method' =>
      'ข้อมูลบัญชีรับเงินไม่ถูกต้อง กรุณาแก้ไขบัญชีธนาคาร',
    _ => 'ถอนเงินไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
  };

  /// The fix is in the bank-account screen.
  bool get needsBankAccount =>
      code == 'no_payout_method' ||
      code == 'unknown_bank' ||
      code == 'invalid_payout_method';

  @override
  String toString() => 'Exception: $message';
}

/// Bumped when a `payout_<status>` push arrives so open payout screens and the
/// wallet balance refresh. A plain notifier: the push service has no Riverpod.
class PayoutUpdates extends ChangeNotifier {
  PayoutUpdates._();
  static final PayoutUpdates instance = PayoutUpdates._();

  void notifyChanged() => notifyListeners();
}

/// A withdrawal request the backend accepted: what it recorded as withheld
/// and what will reach the bank (POST /api/driver/payouts response).
@immutable
class PayoutReceipt {
  const PayoutReceipt({this.whtAmount, this.netAmount});

  final double? whtAmount;
  final double? netAmount;

  factory PayoutReceipt.fromJson(Map<String, dynamic>? j) {
    final body = j?['payout'] is Map
        ? Map<String, dynamic>.from(j!['payout'] as Map)
        : j;
    return PayoutReceipt(
      whtAmount: (body?['wht_amount'] as num?)?.toDouble(),
      netAmount: (body?['net_amount'] as num?)?.toDouble(),
    );
  }
}

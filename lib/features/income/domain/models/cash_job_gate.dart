import 'package:dio/dio.dart';
import 'package:massdrive/core/utils/baht.dart';

/// Admin-set notice from `credit_warning` on GET /api/driver/payouts/summary.
class CreditWarning {
  final String title;
  final String message;

  const CreditWarning({required this.title, required this.message});

  static CreditWarning? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = raw['title']?.toString().trim() ?? '';
    final message = raw['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return null;
    return CreditWarning(title: title, message: message);
  }
}

/// Cash-job gate (BE dev115). Below the admin threshold (default −฿20) the
/// driver gets no cash jobs; QR / card jobs and going online are never
/// blocked. The backend decides — the app only reads
/// `can_receive_cash_jobs` and shows its numbers and copy.
class CashJobGate {
  static const blockedReason = 'CASH_JOBS_BLOCKED';
  static const defaultBlockedTitle = 'งานเงินสดถูกระงับ';
  static const defaultBlockedMessage =
      'ยอดเครดิตต่ำกว่าเกณฑ์ รับได้เฉพาะงานที่จ่ายผ่าน QR/บัตร '
      'เติมเงินเครดิตเพื่อรับงานเงินสดอีกครั้ง';

  /// `credit_balance`, signed.
  final double balance;

  /// `can_receive_cash_jobs`; a missing field never blocks.
  final bool canReceiveCashJobs;

  /// `cash_job_block_balance`, e.g. −20. Null when the backend didn't send it.
  final double? blockBalance;

  /// `reason`: [blockedReason] when blocked, empty otherwise.
  final String reason;

  /// `credit_warning`: the block notice, or a "เครดิตเหลือน้อย" heads-up.
  final CreditWarning? warning;

  const CashJobGate({
    required this.balance,
    this.canReceiveCashJobs = true,
    this.blockBalance,
    this.reason = '',
    this.warning,
  });

  factory CashJobGate.fromSummary(Map<String, dynamic> summary) => CashJobGate(
    balance: (summary['credit_balance'] as num?)?.toDouble() ?? 0,
    canReceiveCashJobs: (summary['can_receive_cash_jobs'] as bool?) ?? true,
    blockBalance: (summary['cash_job_block_balance'] as num?)?.toDouble(),
    reason: summary['reason']?.toString() ?? '',
    warning: CreditWarning.fromJson(summary['credit_warning']),
  );

  /// Cash jobs are off; QR / card jobs still come in.
  bool get cashBlocked => !canReceiveCashJobs;

  /// Anything to show on home: the block, or a low-credit warning.
  bool get hasNotice => cashBlocked || warning != null;

  String get title {
    final t = warning?.title ?? '';
    if (t.isNotEmpty) return t;
    return cashBlocked ? defaultBlockedTitle : 'เครดิตเหลือน้อย';
  }

  String get message {
    final m = warning?.message ?? '';
    if (m.isNotEmpty) return m;
    return cashBlocked ? defaultBlockedMessage : '';
  }

  /// "รับได้เฉพาะงาน QR/บัตร · ยอด -฿35 · เกณฑ์ -฿20" (block) or
  /// "ยอด ฿5 · เกณฑ์ -฿20" (warning).
  String get statusLine {
    final parts = <String>[
      if (cashBlocked) 'รับได้เฉพาะงาน QR/บัตร',
      'ยอด ${formatSignedBaht(balance)}',
      if (blockBalance != null) 'เกณฑ์ ${formatSignedBaht(blockBalance!)}',
    ];
    return parts.join(' · ');
  }
}

/// Thrown by accept calls the backend refused because cash jobs are blocked.
class CashJobBlockedException implements Exception {
  final String serverMessage;

  const CashJobBlockedException([this.serverMessage = '']);

  @override
  String toString() => CashJobGate.defaultBlockedMessage;
}

/// 403 from a job accept because the wallet is below the cash-job limit:
/// food `wallet balance is below the cash-job limit…`, messenger
/// `driver is blocked from cash-on-delivery orders`, or `CASH_JOBS_BLOCKED`.
bool isCashJobBlockedError(Object error) {
  if (error is CashJobBlockedException) return true;
  if (error is! DioException) return false;
  if (error.response?.statusCode != 403) return false;
  final data = error.response?.data;
  final text = switch (data) {
    Map() => [
      data['code'],
      data['reason'],
      data['error'],
      data['message'],
    ].whereType<Object>().join(' '),
    String() => data,
    _ => '',
  }.toLowerCase();
  return text.contains(CashJobGate.blockedReason.toLowerCase()) ||
      text.contains('cash-job') ||
      text.contains('cash job') ||
      text.contains('cash-on-delivery');
}

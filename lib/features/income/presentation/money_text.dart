import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';

/// Money copy shared by the income / wallet screens, kept out of build() so
/// every figure the driver reads is unit-tested.

/// A transaction row's amount: `+฿2` in, `-฿0.40` out, `฿0` for nothing.
String transactionAmountText(Transaction t) =>
    formatSignedBaht(t.amount, plus: true);

/// One-line earnings breakdown ("ยอดงาน ฿2 · หักค่าคอม ฿0.40"), or null when
/// the API sent nothing meaningful (a plain top-up / withdrawal).
String? transactionBreakdown(Transaction t) {
  final parts = <String>[];
  if (t.subtotal != null && t.subtotal! > 0) {
    parts.add('ยอดงาน ${formatBaht(t.subtotal!)}');
  }
  if (t.commission != null && t.commission! > 0) {
    parts.add('หักค่าคอม ${formatBaht(t.commission!)}');
  }
  if (t.platformFee != null && t.platformFee! > 0) {
    parts.add('ค่าธรรมเนียม ${formatBaht(t.platformFee!)}');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Fare earnings for a period (trip calendar): the signed sum, so a reversal
/// lowers it, over rows that didn't fail or get rejected.
double sumEarnings(Iterable<Transaction> txns) => txns
    .where(
      (t) =>
          t.status != TransactionStatus.failed &&
          t.status != TransactionStatus.rejected,
    )
    .fold<double>(0, (sum, t) => sum + t.amount);

/// A wallet balance that may be negative (credit after commission): `-฿13`.
String balanceText(double balance) => formatSignedBaht(balance);

/// The settle-debt hint under the credit figure. Below the cash-job limit
/// only cash jobs stop (BE dev115), so that's what the hint says.
String creditBalanceHint(double creditBalance, {bool cashBlocked = false}) {
  if (cashBlocked) {
    return 'เครดิตติดลบ ${formatBaht(creditBalance)} — '
        'เติมเครดิตเพื่อรับงานเงินสดอีกครั้ง';
  }
  return creditBalance < 0
      ? 'เครดิตติดลบ ${formatBaht(creditBalance)}'
      : 'เครดิตคงเหลือ ${formatBaht(creditBalance)}';
}

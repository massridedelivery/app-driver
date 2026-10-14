import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
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

/// The settle-debt hint under the credit figure.
String creditBalanceHint(double creditBalance) => creditBalance < 0
    ? 'เครดิตติดลบ ${formatBaht(creditBalance)} — เติมให้เป็นบวกเพื่อรับงานต่อได้'
    : 'เครดิตคงเหลือ ${formatBaht(creditBalance)}';

/// Title + body of the low-credit dialog on home. `blocking` (empty/negative,
/// can't receive jobs) uses the stronger copy.
({String title, String message}) creditWarningCopy(
  CreditStatus status, {
  required bool blocking,
}) {
  final balance = balanceText(status.balance);
  // Prefer the per-service breakdown ("Standard Bike ฿30, Saver Bike ฿30"),
  // else a single overall minimum.
  final minLine = status.serviceMinimums.isNotEmpty
      ? status.serviceMinimums
            .map((s) => '${s.name} ${formatBaht(s.min)}')
            .join(', ')
      : formatBaht(status.minBalanceRequired);
  return blocking
      ? (
          title: 'เครดิตไม่พอรับงาน',
          message:
              'เครดิตคงเหลือ $balance — ไม่สามารถรับงานได้\n'
              'กรุณาเติมเงินเครดิตก่อน ระบบจึงจะจ่ายงานให้\n\n'
              'ยอดขั้นต่ำ: $minLine',
        )
      : (
          title: 'เครดิตใกล้หมด',
          message:
              'เครดิตคงเหลือ $balance ไม่พอสำหรับบางประเภทบริการที่คุณลงทะเบียน\n'
              'คุณอาจรับงานได้อีกไม่กี่งาน กรุณาเติมเงินเครดิตเพื่อรับงานต่อเนื่อง\n\n'
              'ยอดขั้นต่ำ: $minLine',
        );
}

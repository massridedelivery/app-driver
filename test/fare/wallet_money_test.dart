import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/income/domain/models/held_fare.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/money_text.dart';

/// Flow 8 — income, cash/credit wallets, settle-debt, withdrawals, held fares.
void main() {
  group('wallet balances', () {
    test('positive, negative and satang balances', () {
      expect(balanceText(1250), '฿1,250');
      expect(balanceText(-13), '-฿13'); // used to read "฿-13"
      expect(balanceText(-0.4), '-฿0.40'); // used to read "฿-0"
      expect(balanceText(99.6), '฿99.60'); // used to read "฿100"
      expect(balanceText(0), '฿0');
    });

    test('settle-debt hint never doubles the minus', () {
      expect(
        creditBalanceHint(-13),
        'เครดิตติดลบ ฿13 — เติมให้เป็นบวกเพื่อรับงานต่อได้',
      );
      expect(creditBalanceHint(40), 'เครดิตคงเหลือ ฿40');
    });
  });

  group('low-credit dialog on home', () {
    test('blocking copy with per-service minimums', () {
      const status = CreditStatus(
        balance: -13,
        canReceiveJobs: false,
        minBalanceRequired: 25,
        serviceMinimums: [
          ServiceMinimum('Standard Bike', 30),
          ServiceMinimum('Saver Bike', 25.5),
        ],
      );
      final c = creditWarningCopy(status, blocking: true);
      expect(c.title, 'เครดิตไม่พอรับงาน');
      expect(c.message, contains('เครดิตคงเหลือ -฿13 — ไม่สามารถรับงานได้'));
      expect(
        c.message,
        contains('ยอดขั้นต่ำ: Standard Bike ฿30, Saver Bike ฿25.50'),
      );
    });

    test('warning copy falls back to the overall minimum', () {
      const status = CreditStatus(
        balance: 12,
        canReceiveJobs: true,
        minBalanceRequired: 25,
      );
      final c = creditWarningCopy(status, blocking: false);
      expect(c.title, 'เครดิตใกล้หมด');
      expect(c.message, startsWith('เครดิตคงเหลือ ฿12 ไม่พอ'));
      expect(c.message, endsWith('ยอดขั้นต่ำ: ฿25'));
    });
  });

  group('withdrawal tax (หัก ณ ที่จ่าย)', () {
    // A summary that withholds 1% (the rule still holds if it ever returns).
    const limits = PayoutLimits(whtRate: 0.01);

    test('matches the backend rule: wht = round(amount × 1%, 2)', () {
      expect(limits.whtFor(1000), 10);
      expect(limits.whtFor(150), 1.5);
      expect(limits.whtFor(1234.56), 12.35);
      expect(limits.whtFor(100), 1);
    });

    test('net = amount − wht, so the breakdown always adds up', () {
      for (final amount in [100.0, 150.0, 999.99, 1234.56, 50000.0]) {
        final wht = limits.whtFor(amount);
        final net = limits.netFor(amount);
        expect(
          ((wht + net) * 100).round(),
          (amount * 100).round(),
          reason: '$amount',
        );
      }
      expect(limits.netFor(1000), 990);
      expect(formatBaht(limits.netFor(150)), '฿148.50');
      expect(formatBaht(limits.whtFor(150)), '฿1.50');
    });

    test('a different rate from the summary is honoured', () {
      final l = PayoutLimits.fromSummary({'wht_rate': 0.03});
      expect(l.whtFor(1000), 30);
      expect(l.netFor(1000), 970);
    });

    test('a small balance can be withdrawn (no ฿100 minimum)', () {
      final l = PayoutLimits.fromSummary({
        'min_withdraw': 0,
        'has_payout_method': true,
      });
      expect(l.blockReason(availableBalance: 0.99), isNull);
      expect(l.blockReason(availableBalance: 0), 'ยังไม่มียอดที่ถอนได้');
    });
  });

  test('held fare amount', () {
    final h = HeldFare.fromJson({
      'id': 'h',
      'amount': 82.5,
      'status': 'PENDING',
    });
    expect(h.amount, 82.5);
    expect(formatBaht(h.amount), '฿82.50');
    expect(HeldFare.fromJson({'id': 'h'}).amount, 0);
  });
}

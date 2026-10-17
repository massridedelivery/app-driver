import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';

/// Backend dev103: no ฿100 minimum, 3 withdrawals a day, decimals allowed.
void main() {
  final limits = PayoutLimits.fromSummary({
    'min_withdraw': 0,
    'max_withdraw': 50000,
    'max_per_day': 3,
    'withdrawals_today': 1,
    'wht_rate': 0.01,
    'has_payout_method': true,
  });

  group('amount', () {
    test('any amount above 0 up to the balance and ฿50,000', () {
      expect(limits.amountError(1, availableBalance: 500), isNull);
      expect(limits.amountError(0.5, availableBalance: 500), isNull);
      expect(limits.amountError(120.75, availableBalance: 500), isNull);
      expect(limits.amountError(500, availableBalance: 500), isNull);
    });

    test('0 / empty → must be more than 0 (min is exclusive)', () {
      expect(
        limits.amountError(0, availableBalance: 500),
        'กรุณาใส่จำนวนเงินมากกว่า 0',
      );
      expect(
        limits.amountError(null, availableBalance: 500),
        'กรุณาใส่จำนวนเงินมากกว่า 0',
      );
    });

    test('over the balance, over the max, more than 2 decimals', () {
      expect(
        limits.amountError(501, availableBalance: 500),
        'ยอดเงินไม่เพียงพอ',
      );
      expect(
        limits.amountError(50001, availableBalance: 90000),
        'ถอนได้สูงสุด ฿50,000 ต่อครั้ง',
      );
      expect(
        limits.amountError(1.234, availableBalance: 500),
        'ใส่ทศนิยมได้ไม่เกิน 2 ตำแหน่ง',
      );
    });

    test('ถอน ฿1 → ได้รับ ฿0.99 (net = amount − round(amount × 1%, 2))', () {
      expect(limits.whtFor(1), 0.01);
      expect(formatBaht(limits.netFor(1)), '฿0.99');
      expect(formatBaht(limits.netFor(0.5)), '฿0.49'); // wht 0.005 → 0.01
    });
  });

  group('per day', () {
    test('remaining today = max_per_day − withdrawals_today', () {
      expect(limits.remainingToday, 2);
      expect(limits.blockReason(availableBalance: 10), isNull);
    });

    test('3 of 3 → blocked until tomorrow', () {
      final full = PayoutLimits.fromSummary({
        'max_per_day': 3,
        'withdrawals_today': 3,
        'has_payout_method': true,
      });
      expect(full.remainingToday, 0);
      expect(full.dailyLimitReached, isTrue);
      expect(
        full.blockReason(availableBalance: 100),
        'ครบ 3 ครั้งแล้ววันนี้ ถอนได้อีกครั้งพรุ่งนี้',
      );
    });

    test('defaults before the summary loads: no minimum, 3 a day', () {
      const d = PayoutLimits();
      expect(d.minWithdraw, 0);
      expect(d.maxPerDay, 3);
    });
  });

  group('backend codes', () {
    String msg(String code) => PayoutException(code, 'english').message;
    test('Thai copy per code', () {
      expect(msg('payout_below_min'), 'กรุณาใส่จำนวนเงินมากกว่า 0');
      expect(msg('payout_above_max'), 'ถอนได้สูงสุด 50,000 บาทต่อครั้ง');
      expect(msg('payout_limit_exceeded'), 'ถอนครบ 3 ครั้งแล้ววันนี้');
      expect(
        msg('payout_pending_exists'),
        'มีคำขอถอนที่รอดำเนินการอยู่ รอให้เสร็จก่อนถอนใหม่',
      );
    });
  });

  test('receipt reads wht_amount / net_amount from the response', () {
    final r = PayoutReceipt.fromJson({
      'id': 'p',
      'amount': 1,
      'wht_amount': 0.01,
      'net_amount': 0.99,
    });
    expect(r.whtAmount, 0.01);
    expect(r.netAmount, 0.99);
    final nested = PayoutReceipt.fromJson({
      'payout': {'wht_amount': 1.5, 'net_amount': 148.5},
    });
    expect(nested.netAmount, 148.5);
    expect(PayoutReceipt.fromJson(null).netAmount, isNull);
  });

  test('no withholding (wht_rate 0): ถอน ฿10 ได้รับ ฿10 เต็ม', () {
    final l = PayoutLimits.fromSummary({'wht_rate': 0, 'max_per_day': 3});
    expect(l.whtFor(10), 0);
    expect(l.netFor(10), 10);
    final r = PayoutReceipt.fromJson({
      'amount': 10,
      'wht_amount': 0,
      'net_amount': 10,
    });
    expect(r.whtAmount, 0);
    expect(r.netAmount, 10);
  });
}

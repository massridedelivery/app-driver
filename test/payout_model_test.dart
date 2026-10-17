import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';

void main() {
  group('PayoutLimits', () {
    test('reads the summary fields', () {
      final l = PayoutLimits.fromSummary({
        'min_withdraw': 100,
        'max_withdraw': 50000,
        'max_per_day': 5,
        'withdrawals_today': 2,
        'wht_rate': 0.01,
        'has_payout_method': true,
        'payout_method_pending': false,
      });
      expect(l.withdrawalsToday, 2);
      expect(l.netFor(1000), 990);
      expect(l.blockReason(availableBalance: 500), isNull);
    });

    test('defaults to 1% and does not block when the backend is older', () {
      final l = PayoutLimits.fromSummary({'available_balance': 500});
      expect(l.whtRate, 0.01);
      expect(l.hasPayoutMethod, isNull);
      expect(l.blockReason(availableBalance: 500), isNull);
    });

    test('blocks with a reason before calling the API', () {
      expect(
        PayoutLimits.fromSummary({
          'has_payout_method': false,
        }).blockReason(availableBalance: 500),
        contains('เพิ่มบัญชีธนาคาร'),
      );
      expect(
        PayoutLimits.fromSummary({
          'payout_method_pending': true,
        }).blockReason(availableBalance: 500),
        contains('ระหว่างตรวจสอบ'),
      );
      expect(
        PayoutLimits.fromSummary({
          'withdrawals_today': 5,
          'max_per_day': 5,
        }).blockReason(availableBalance: 500),
        contains('ครบ 5 ครั้ง'),
      );
      // No minimum any more (dev103) — only an empty balance blocks.
      expect(const PayoutLimits().blockReason(availableBalance: 50), isNull);
      expect(
        const PayoutLimits().blockReason(availableBalance: 0),
        'ยังไม่มียอดที่ถอนได้',
      );
    });
  });

  group('PayoutRecord', () {
    test('parses status, reason and bank display name', () {
      final r = PayoutRecord.fromJson({
        'id': 'p1',
        'amount': 200,
        'status': 'failed',
        'failure_reason': 'บัญชีปลายทางไม่ถูกต้อง',
        'rejection_reason': null,
        'method_details': {
          'bank_name': '004',
          'bank_display_name': 'ธนาคารกสิกรไทย',
          'account_number': '0653334521',
        },
        'created_at': '2026-10-12T04:35:38Z',
      });
      expect(r.status, PayoutStatus.failed);
      expect(r.status.label, 'โอนไม่สำเร็จ');
      expect(r.reason, 'บัญชีปลายทางไม่ถูกต้อง');
      expect(r.bankName, 'ธนาคารกสิกรไทย');
      expect(r.maskedAccount, 'xxxxxx4521');
    });

    test('unknown status does not crash', () {
      expect(
        PayoutRecord.fromJson({'status': 'weird'}).status,
        PayoutStatus.unknown,
      );
    });
  });

  group('PayoutException', () {
    test('maps every backend code to Thai', () {
      for (final code in [
        'payout_below_min',
        'payout_above_max',
        'payout_limit_exceeded',
        'insufficient_balance',
        'payout_pending_exists',
        'no_payout_method',
        'payout_method_pending',
        'unknown_bank',
        'invalid_payout_method',
      ]) {
        final m = PayoutException(code, 'english').message;
        expect(m, isNot(contains('english')), reason: code);
        expect(m, isNot('ถอนเงินไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), reason: code);
      }
    });

    test('bank-account codes point the driver to fix the account', () {
      expect(
        const PayoutException('unknown_bank', null).needsBankAccount,
        isTrue,
      );
      expect(
        const PayoutException('payout_limit_exceeded', null).needsBankAccount,
        isFalse,
      );
    });
  });
}

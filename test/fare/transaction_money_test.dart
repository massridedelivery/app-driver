import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/income/presentation/money_text.dart';
import 'package:massdrive/features/wallet/data/models/transaction_model.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

/// Flow 7 — รายการทั้งหมด (wallet transactions) and the trip calendar total.
Transaction _tx(Map<String, dynamic> j) => TransactionModel.fromJson({
  'id': 't',
  'type': 'FARE_PAYMENT',
  'status': 'COMPLETED',
  'created_at': '2026-09-19T03:19:00Z',
  ...j,
}).toEntity();

void main() {
  group('parsing', () {
    test('fare row with its breakdown', () {
      final t = _tx({
        'amount': 2,
        'subtotal': 2,
        'commission': 0.4,
        'job_id': 'JOB-1',
      });
      expect(t.type, TransactionType.farePayment);
      expect(t.status, TransactionStatus.completed);
      expect(t.amount, 2);
      expect(t.subtotal, 2);
      expect(t.commission, 0.4);
      expect(t.jobId, 'JOB-1');
    });

    test('commission row is a negative amount (a debit)', () {
      final t = _tx({'type': 'COMMISSION_DEDUCTION', 'amount': -0.4});
      expect(t.type, TransactionType.commissionDeduction);
      expect(t.isDebit, isTrue);
      expect(t.absoluteAmount, 0.4);
    });
  });

  group('row amount', () {
    test('credit gets +, debit gets −, with satang', () {
      expect(transactionAmountText(_tx({'amount': 2})), '+฿2');
      expect(transactionAmountText(_tx({'amount': -0.4})), '-฿0.40');
      expect(transactionAmountText(_tx({'amount': 100})), '+฿100');
      expect(transactionAmountText(_tx({'amount': -1500})), '-฿1,500');
    });

    test('a zero row is ฿0 — not "-฿0" or "+฿0"', () {
      expect(transactionAmountText(_tx({'amount': 0})), '฿0');
      expect(transactionAmountText(_tx({'amount': -0.001})), '฿0');
    });
  });

  group('breakdown line', () {
    test('small commission keeps its satang', () {
      final t = _tx({'amount': 2, 'subtotal': 2, 'commission': 0.4});
      expect(transactionBreakdown(t), 'ยอดงาน ฿2 · หักค่าคอม ฿0.40');
    });

    test('includes the platform fee when there is one', () {
      final t = _tx({
        'amount': 100,
        'subtotal': 120,
        'commission': 18,
        'platform_fee': 2,
      });
      expect(
        transactionBreakdown(t),
        'ยอดงาน ฿120 · หักค่าคอม ฿18 · ค่าธรรมเนียม ฿2',
      );
    });

    test('nothing meaningful → no line (top-up / withdrawal)', () {
      expect(
        transactionBreakdown(_tx({'type': 'TOPUP', 'amount': 100})),
        isNull,
      );
      expect(
        transactionBreakdown(
          _tx({'amount': 5, 'subtotal': 0, 'commission': 0}),
        ),
        isNull,
      );
    });
  });

  test('marketing_expense is the promo row, not an adjustment', () {
    final t = _tx({'type': 'marketing_expense', 'amount': 50, 'job_id': 'J'});
    expect(t.type, TransactionType.promoDiscount);
    expect(TransactionType.promoDiscount.toApiString(), 'MARKETING_EXPENSE');
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/income/presentation/statement_entries.dart';
import 'package:massdrive/features/wallet/data/models/transaction_model.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';

/// BE #198 accept outcomes, and รายการทั้งหมด (jobs) vs ประวัติเครดิต (wallet).
DioException _err(int code, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/api/driver/jobs/J/accept'),
  response: Response(
    requestOptions: RequestOptions(path: ''),
    statusCode: code,
    data: body,
  ),
);

Transaction _tx(String id, String type, num amount, {String? job}) =>
    TransactionModel.fromJson({
      'id': id,
      'type': type,
      'amount': amount,
      'status': 'COMPLETED',
      'created_at': '2026-10-16T00:50:00Z',
      if (job != null) 'job_id': job,
    }).toEntity();

void main() {
  group('accept', () {
    test('409 job_taken → taken (someone else got it), not cancelled', () {
      expect(isJobTakenError(_err(409, {'code': 'job_taken'})), isTrue);
      expect(acceptOutcomeMessage(AcceptOutcome.taken), 'มีคนรับงานนี้ไปแล้ว');
    });

    test('other failures are not "taken" — the app re-checks /active', () {
      expect(isJobTakenError(_err(409, {'code': 'job_cancelled'})), isFalse);
      expect(isJobTakenError(_err(503, {'error': 'retry'})), isFalse);
      expect(isJobTakenError(_err(400, {'code': 'job_taken'})), isFalse);
      expect(isJobTakenError(Exception('timeout')), isFalse);
      expect(
        acceptOutcomeMessage(AcceptOutcome.failed),
        'รับงานไม่สำเร็จ กรุณาลองใหม่',
      );
    });
  });

  group('statement scope', () {
    final txns = [
      _tx('c', 'COMMISSION_DEDUCTION', -7, job: 'J1'),
      _tx('f', 'FARE_PAYMENT', 44, job: 'J1'),
      _tx('t', 'TOPUP', 100),
      _tx('a', 'ADJUSTMENT', 100),
    ];

    test('รายการทั้งหมด shows driving only', () {
      final e = buildStatement(txns, scope: StatementScope.jobs);
      expect(e.whereType<StatementJob>().map((j) => j.jobId), ['J1']);
      expect(e.whereType<StatementTxn>(), isEmpty);
    });

    test('ประวัติเครดิต shows top-ups / adjustments only', () {
      final e = buildStatement(txns, scope: StatementScope.wallet);
      expect(e.whereType<StatementJob>(), isEmpty);
      expect(e.whereType<StatementTxn>().map((t) => t.transaction.id), [
        't',
        'a',
      ]);
    });

    test('all keeps both', () {
      final e = buildStatement(txns);
      expect(e.whereType<StatementJob>().length, 1);
      expect(e.whereType<StatementTxn>().length, 2);
    });
  });

  group('active job read (BE #199 cases, commission 15%)', () {
    IncomingJobModel job(Map<String, dynamic> extra) =>
        IncomingJobModel.fromJson({
          'id': 'J',
          'pickup_address': 'A',
          'dropoff_address': 'B',
          'pickup_lat': 18.5,
          'pickup_lng': 99.0,
          'dropoff_lat': 18.6,
          'dropoff_lng': 99.1,
          'payment_method': 'CASH',
          'fare': 44,
          'driver_earnings': {
            'commission_rate': 0.15,
            'commission': 7,
            'driver_net': 37,
          },
          ...extra,
        });

    test('A: cash 44, coupon 44 → collect 0, net 37', () {
      final j = job({'discount': 44, 'amount_due': 0});
      expect(j.amountDue, 0);
      expect(j.discount, 44);
      expect(j.driverNet, 37);
      expect(j.driverCommission, 7);
      expect(j.netIncome + j.tollFee + j.waitingFee - j.discount, j.amountDue);
    });

    test('B: cash 44, coupon 20 → collect 24, net still 37', () {
      final j = job({'discount': 20, 'amount_due': 24});
      expect(j.amountDue, 24);
      expect(j.driverNet, 37);
    });

    test('C: QR 44 paid → collect 0, payment_status PAID', () {
      final j = job({
        'payment_method': 'PROMPTPAY',
        'amount_due': 0,
        'payment_status': 'PAID',
      });
      expect(j.amountDue, 0);
      expect(j.paymentStatus, 'PAID');
    });

    test('toll and waiting are read for the breakdown', () {
      final j = job({'toll_fee': 25, 'waiting_fee': 6, 'amount_due': 75});
      expect(j.tollFee, 25);
      expect(j.waitingFee, 6);
      expect(j.netIncome + j.tollFee + j.waitingFee - j.discount, j.amountDue);
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';
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
}

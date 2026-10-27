import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/payment/domain/collection_amounts.dart';
import 'package:massdrive/features/wallet/data/models/transaction_model.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

/// BE PR #15: a customer's earlier cancel fee carried onto the next job.
IncomingJobModel _job([Map<String, dynamic> extra = const {}]) =>
    IncomingJobModel.fromJson({
      'id': 'JOB-1',
      'pickup_address': 'A',
      'dropoff_address': 'B',
      'pickup_lat': 13.7,
      'pickup_lng': 100.5,
      'dropoff_lat': 13.8,
      'dropoff_lng': 100.6,
      'payment_method': 'CASH',
      'fare': 60,
      ...extra,
    });

void main() {
  group('job prior_cancel_fee', () {
    test('cash job: collect amount_due, which already holds the fee', () {
      final j = _job({'prior_cancel_fee': 20, 'amount_due': 80});
      expect(j.priorCancelFee, 20);
      expect(rideAmountToCollect(serverAmountDue: j.amountDue!), 80);
      expect(
        j.priorCancelFeeLine,
        'ค่ายกเลิกครั้งก่อนของลูกค้า ฿20 (เก็บแทนบริษัท)',
      );
    });

    test('satang amounts keep two decimals', () {
      expect(
        _job({'prior_cancel_fee': 12.5}).priorCancelFeeLine,
        'ค่ายกเลิกครั้งก่อนของลูกค้า ฿12.50 (เก็บแทนบริษัท)',
      );
    });

    test('missing, null or 0 means no fee and no line', () {
      for (final j in [
        _job(),
        _job({'prior_cancel_fee': null}),
        _job({'prior_cancel_fee': 0, 'amount_due': 60}),
      ]) {
        expect(j.priorCancelFee, 0);
        expect(j.priorCancelFeeLine, isNull);
      }
    });

    test('QR job shows the line too (the fee is in its amount_due)', () {
      final j = _job({
        'payment_method': 'PROMPTPAY',
        'prior_cancel_fee': 20,
        'amount_due': 80,
      });
      expect(j.priorCancelFeeLine, isNotNull);
    });
  });

  group('CANCELLATION_FEE_COLLECTED', () {
    test('parses as its own type: a debit with a Thai label', () {
      final t = TransactionModel.fromJson({
        'id': 't',
        'type': 'CANCELLATION_FEE_COLLECTED',
        'amount': -20,
        'status': 'COMPLETED',
        'job_id': 'JOB-1',
        'created_at': '2026-10-27T03:00:00Z',
      }).toEntity();
      expect(t.type, TransactionType.cancellationFeeCollected);
      expect(t.isDebit, isTrue);
      expect(t.description, cancellationFeeCollectedLabel);
      expect(
        TransactionType.cancellationFeeCollected.toApiString(),
        'CANCELLATION_FEE_COLLECTED',
      );
    });

    test('trip history card line has the Thai label', () {
      final i = HistoryItemModel(
        id: 't',
        dateTime: DateTime(2026, 10, 27),
        title: 'CANCELLATION_FEE_COLLECTED',
        amount: -20,
        status: HistoryStatus.completed,
        serviceType: ServiceType.ride,
        rawType: 'CANCELLATION_FEE_COLLECTED',
        jobId: 'JOB-1',
      );
      expect(historyLineLabel(i), 'ค่ายกเลิกที่เก็บแทนบริษัท');
    });
  });
}

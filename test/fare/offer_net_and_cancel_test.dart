import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/domain/models/offer_headline.dart';

/// BE #191 — driver's net on the offer card, and leaving a cancelled job.
Map<String, dynamic> _offer([Map<String, dynamic> extra = const {}]) => {
  'id': 'JOB-1',
  'pickup_address': 'A',
  'dropoff_address': 'B',
  'pickup_lat': 13.7,
  'pickup_lng': 100.5,
  'dropoff_lat': 13.8,
  'dropoff_lng': 100.6,
  'payment_method': 'CASH',
  'fare': 40,
  ...extra,
};

void main() {
  group('offer card headline', () {
    test('driver_earnings.driver_net → รายได้สุทธิ ฿32 (fare ฿40, 20%)', () {
      final job = IncomingJobModel.fromJson(
        _offer({
          'driver_earnings': {
            'commission_rate': 0.2,
            'commission': 8,
            'driver_net': 32,
          },
        }),
      );
      expect(job.driverNet, 32);
      expect(job.driverCommission, 8); // shown as หักค่าคอมมิชชัน on collect
      expect(job.netIncome - job.driverCommission!, job.driverNet);
      final h = offerHeadline(fare: job.netIncome, driverNet: job.driverNet);
      expect(h.label, 'รายได้สุทธิ');
      expect(h.amount, 32);
    });

    test(
      'no driver_earnings → the fare, called ค่าโดยสาร (never รายได้สุทธิ)',
      () {
        final job = IncomingJobModel.fromJson(_offer());
        expect(job.driverNet, isNull);
        final h = offerHeadline(fare: job.netIncome, driverNet: job.driverNet);
        expect(h.label, 'ค่าโดยสาร');
        expect(h.amount, 40);
      },
    );

    test('food / messenger without a net → ค่าส่ง', () {
      final h = offerHeadline(fare: 25, delivery: true);
      expect(h.label, 'ค่าส่ง');
      expect(h.amount, 25);
      expect(
        offerHeadline(fare: 25, driverNet: 20, delivery: true).label,
        'รายได้สุทธิ',
      );
    });
  });

  group('cancellation sources', () {
    test('WS job_status CANCELLED, top-level or under data', () {
      final a = jobCancelFromSocket('job_status', {
        'type': 'job_status',
        'job_id': 'J1',
        'status': 'CANCELLED',
        'cancelled_by': 'customer',
      }, null);
      expect(a!.jobId, 'J1');
      expect(a.cancelledBy, 'customer');

      final b = jobCancelFromSocket('job_status', {}, {
        'job_id': 'J2',
        'status': 'cancelled',
      });
      expect(b!.jobId, 'J2');
      expect(b.cancelledBy, isNull);
    });

    test('food ORDER_STATUS_UPDATED with orderId counts too', () {
      final e = jobCancelFromSocket('ORDER_STATUS_UPDATED', {
        'orderId': 'F1',
        'status': 'CANCELLED',
      }, null);
      expect(e!.jobId, 'F1');
    });

    test('other statuses / types are not cancellations', () {
      expect(
        jobCancelFromSocket('job_status', {
          'job_id': 'J',
          'status': 'PICKED_UP',
        }, null),
        isNull,
      );
      expect(
        jobCancelFromSocket('job_offer', {
          'job_id': 'J',
          'status': 'CANCELLED',
        }, null),
        isNull,
      );
      expect(
        jobCancelFromSocket('job_status', {'status': 'CANCELLED'}, null),
        isNull,
      );
    });

    test('push job_cancelled', () {
      final e = jobCancelFromPush({
        'type': 'job_cancelled',
        'job_id': 'J3',
        'cancelled_by': 'admin',
      });
      expect(e!.jobId, 'J3');
      expect(e.cancelledBy, 'admin');
      expect(
        jobCancelFromPush({'type': 'payout_completed', 'job_id': 'J'}),
        isNull,
      );
    });

    test('409 job_cancelled from the status PATCH — and nothing else', () {
      DioException err(int code, Object? body) => DioException(
        requestOptions: RequestOptions(path: '/api/driver/jobs/J/status'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: code,
          data: body,
        ),
      );
      expect(isJobCancelledError(err(409, {'code': 'job_cancelled'})), isTrue);
      expect(isJobCancelledError(err(400, {'code': 'job_cancelled'})), isFalse);
      expect(isJobCancelledError(err(409, {'code': 'other'})), isFalse);
      expect(isJobCancelledError(err(409, 'x')), isFalse);
      expect(isJobCancelledError(Exception('x')), isFalse);
    });
  });

  test('message names who cancelled', () {
    expect(jobCancelledMessage('customer'), 'งานถูกยกเลิกโดยผู้โดยสาร');
    expect(
      jobCancelledMessage('customer', food: true),
      'งานถูกยกเลิกโดยลูกค้า',
    );
    expect(jobCancelledMessage('admin'), 'งานถูกยกเลิกโดยแอดมิน');
    expect(jobCancelledMessage('system'), 'งานถูกยกเลิกโดยระบบ');
    expect(jobCancelledMessage(null), 'งานนี้ถูกยกเลิกแล้ว');
  });

  test(
    'one cancellation reported by WS + push + 409 reaches the UI once',
    () async {
      final got = <String>[];
      final sub = JobCancellations.instance.events.listen(
        (e) => got.add(e.jobId),
      );
      JobCancellations.instance.report(const JobCancelEvent('DUP'));
      JobCancellations.instance.report(
        const JobCancelEvent('DUP', cancelledBy: 'customer'),
      );
      JobCancellations.instance.report(const JobCancelEvent('DUP'));
      JobCancellations.instance.report(const JobCancelEvent('OTHER'));
      await Future<void>.delayed(Duration.zero);
      expect(got, ['DUP', 'OTHER']);
      await sub.cancel();
    },
  );
}

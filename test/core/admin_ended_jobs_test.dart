import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/messenger/domain/messenger_status_override.dart';

void main() {
  group('a ride the back office closes as COMPLETED', () {
    test('WS job_status COMPLETED is a close, not a cancellation', () {
      final e = jobCancelFromSocket('job_status', {
        'type': 'job_status',
        'job_id': 'J1',
        'status': 'COMPLETED',
      }, null)!;
      expect(e.jobId, 'J1');
      expect(e.closedByAdmin, isTrue);
      expect(e.cancelledBy, isNull);
    });

    test('CANCELLED stays a cancellation', () {
      final e = jobCancelFromSocket('job_status', {
        'job_id': 'J2',
        'status': 'CANCELLED',
        'cancelled_by': 'admin',
      }, null)!;
      expect(e.closedByAdmin, isFalse);
      expect(e.cancelledBy, 'admin');
    });

    test('only a ride frame: food COMPLETED is not read as a close', () {
      expect(
        jobCancelFromSocket('ORDER_STATUS_UPDATED', {
          'orderId': 'F1',
          'status': 'COMPLETED',
        }, null),
        isNull,
      );
    });

    test('push job_completed_by_admin', () {
      final e = jobCancelFromPush({
        'type': 'job_completed_by_admin',
        'job_id': 'J3',
      })!;
      expect(e.jobId, 'J3');
      expect(e.closedByAdmin, isTrue);
      expect(jobCancelFromPush({'type': 'job_completed_by_admin'}), isNull);
    });
  });

  group('JobCancellations and the driver completing the ride', () {
    late StreamSubscription<JobCancelEvent> sub;
    late List<JobCancelEvent> got;

    setUp(() {
      JobCancellations.instance.debugReset();
      got = [];
      sub = JobCancellations.instance.events.listen(got.add);
    });
    tearDown(() => sub.cancel());

    test('the COMPLETED frame after the driver\'s own PATCH is dropped',
        () async {
      JobCancellations.instance.markOwnCompletion('J1');
      JobCancellations.instance.report(
        const JobCancelEvent('J1', closedByAdmin: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(got, isEmpty);
    });

    test('a cancellation of that ride still gets through', () async {
      JobCancellations.instance.markOwnCompletion('J2');
      JobCancellations.instance.report(const JobCancelEvent('J2'));
      await Future<void>.delayed(Duration.zero);
      expect(got.single.jobId, 'J2');
    });

    test('after a failed PATCH, a close is the office\'s again', () async {
      JobCancellations.instance.markOwnCompletion('J3');
      JobCancellations.instance.clearOwnCompletion('J3');
      JobCancellations.instance.report(
        const JobCancelEvent('J3', closedByAdmin: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(got.single.closedByAdmin, isTrue);
    });

    test('the WS frame and the push report one close once', () async {
      for (var i = 0; i < 2; i++) {
        JobCancellations.instance.report(
          const JobCancelEvent('J4', closedByAdmin: true),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(got, hasLength(1));
    });
  });

  group('a parcel whose status the back office forces', () {
    test('frame or push: order_id and status, top-level or under data', () {
      final a = messengerStatusOverrideOf('messenger_status_updated', {
        'type': 'messenger_status_updated',
        'order_id': 'M1',
        'status': 'cancelled',
      })!;
      expect(a.orderId, 'M1');
      expect(a.status, 'CANCELLED');
      expect(a.ended, isTrue);

      final b = messengerStatusOverrideOf('messenger_status_updated', {}, {
        'order_id': 'M2',
        'status': 'PICKED_UP',
      })!;
      expect(b.ended, isFalse);

      expect(
        messengerStatusOverrideOf('messenger_status_updated', {
          'order_id': 'M3',
          'status': 'DELIVERED',
        })!.ended,
        isTrue,
      );
    });

    test('other types or missing fields are not overrides', () {
      expect(
        messengerStatusOverrideOf('messenger_cancelled', {
          'order_id': 'M1',
          'status': 'CANCELLED',
        }),
        isNull,
      );
      expect(
        messengerStatusOverrideOf('messenger_status_updated', {
          'status': 'CANCELLED',
        }),
        isNull,
      );
      expect(
        messengerStatusOverrideOf('messenger_status_updated', {
          'order_id': 'M1',
        }),
        isNull,
      );
    });

    test('the WS frame and the push report one override once', () async {
      MessengerStatusOverrides.instance.debugReset();
      final got = <MessengerStatusOverride>[];
      final sub = MessengerStatusOverrides.instance.events.listen(got.add);
      const o = MessengerStatusOverride('M9', 'CANCELLED');
      MessengerStatusOverrides.instance.report(o);
      MessengerStatusOverrides.instance.report(o);
      MessengerStatusOverrides.instance.report(
        const MessengerStatusOverride('M9', 'PICKED_UP'),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(got.map((e) => e.status), ['CANCELLED', 'PICKED_UP']);
    });

    test('Thai text per end', () {
      expect(messengerOverrideEndedMessage('DELIVERED'), contains('ปิดงาน'));
      expect(messengerOverrideEndedMessage('CANCELLED'), contains('ยกเลิก'));
    });
  });

  group('a back-to-back offer', () {
    test('carries next_offer and is told apart from a normal offer', () {
      expect(
        isNextRideOffer({
          'id': 'J5',
          'next_offer': {
            'after_job_id': 'J4',
            'eta_to_dropoff_min': 3,
            'eta_to_pickup_min': 5,
          },
        }),
        isTrue,
      );
      expect(isNextRideOffer({'id': 'J5'}), isFalse);
      expect(isNextRideOffer({'id': 'J5', 'next_offer': null}), isFalse);
      expect(isNextRideOffer(null), isFalse);
    });
  });
}

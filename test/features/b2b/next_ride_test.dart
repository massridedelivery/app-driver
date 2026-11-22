import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/next_ride/data/next_ride_api_service.dart';
import 'package:massdrive/features/next_ride/domain/next_ride.dart';
import 'package:massdrive/features/next_ride/presentation/next_ride_controller.dart';
import 'package:massdrive/features/next_ride/presentation/widgets/next_ride_overlay.dart';

/// A ride as the backend sends it on an offer / job_queued / GET /jobs/next.
Map<String, dynamic> rideJson(
  String id, {
  Map<String, dynamic>? nextOffer,
  Map<String, dynamic>? queuedNext,
  int? timeout,
}) => {
  'id': id,
  'pickup_address': 'สยามพารากอน',
  'dropoff_address': 'สีลม',
  'pickup_lat': 13.746,
  'pickup_lng': 100.534,
  'dropoff_lat': 13.728,
  'dropoff_lng': 100.534,
  'fare': 80,
  'payment_method': 'CASH',
  'driver_earnings': {
    'driver_net': 64,
    'commission': 16,
    'commission_rate': 0.2,
  },
  if (nextOffer != null) 'next_offer': nextOffer,
  if (queuedNext != null) 'queued_next': queuedNext,
  if (timeout != null) 'timeout_seconds': timeout,
};

const nextOffer = {
  'after_job_id': 'A',
  'eta_to_dropoff_min': 4,
  'eta_to_pickup_min': 7,
};

DioException http(int status, [Object? body]) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
);

class FakeApi implements NextRideApiService {
  NextRideAcceptOutcome acceptOutcome = NextRideAcceptOutcome.queued;
  Completer<NextRideAcceptOutcome>? acceptGate;
  Map<String, dynamic>? next;
  Object? nextError;
  Object? unqueueError;
  final accepted = <String>[];
  final unqueued = <String>[];

  @override
  Future<NextRideAcceptOutcome> accept(String jobId) async {
    accepted.add(jobId);
    if (acceptGate != null) return acceptGate!.future;
    return acceptOutcome;
  }

  @override
  Future<Map<String, dynamic>?> getNextRide() async {
    if (nextError != null) throw nextError!;
    return next;
  }

  @override
  Future<void> unqueue(String jobId) async {
    unqueued.add(jobId);
    if (unqueueError != null) throw unqueueError!;
  }
}

class FakeEffects implements NextRideEffects {
  final rejected = <String>[];
  final rung = <String>[];
  final toasts = <String>[];
  var stops = 0;
  IncomingJobModel? active;
  var activeReads = 0;
  Map<String, dynamic>? offerJob;

  @override
  void reject(String jobId) => rejected.add(jobId);

  @override
  void ring(String jobId) => rung.add(jobId);

  @override
  void stopRinging() => stops++;

  @override
  void toast(String message) => toasts.add(message);

  @override
  Future<IncomingJobModel?> activeRide() async {
    activeReads++;
    return active;
  }

  @override
  Future<Map<String, dynamic>?> activeOfferJob() async => offerJob;
}

void main() {
  group('frames', () {
    test('job_offer_next, or an offer carrying next_offer, is the card', () {
      final b2b = rideJson('B', nextOffer: nextOffer);
      expect(
        offerPresentationOf('job_offer_next', b2b),
        OfferPresentation.nextRideCard,
      );
      // Re-sent after a reconnect as a plain job_offer.
      expect(
        offerPresentationOf('job_offer', b2b),
        OfferPresentation.nextRideCard,
      );
      expect(
        offerPresentationOf('scheduled_job_offer', b2b),
        OfferPresentation.nextRideCard,
      );
      expect(
        offerPresentationOf('job_offer', rideJson('C')),
        OfferPresentation.fullScreen,
      );
      expect(offerPresentationOf('job_queued', b2b), OfferPresentation.none);
    });

    test('the offer job comes from {job} or {data: {job}}', () {
      final job = rideJson('B', nextOffer: nextOffer);
      expect(offerJobJson({'type': 'job_offer_next', 'job': job}, null), job);
      expect(offerJobJson({'type': 'job_offer_next'}, {'job': job}), job);
    });

    test('a next-ride offer parses with the usual 16 s window', () {
      final now = DateTime(2026, 11, 22, 10);
      final o = nextRideOfferFromJob(
        rideJson('B', nextOffer: nextOffer),
        now: now,
      )!;
      expect(o.jobId, 'B');
      expect(o.info.afterJobId, 'A');
      expect(o.info.etaToDropoffMin, 4);
      expect(o.info.etaToPickupMin, 7);
      expect(o.totalSeconds, 16);
      expect(o.expiresAt, now.add(const Duration(seconds: 16)));
      expect(o.remainingAt(now.add(const Duration(milliseconds: 10500))), 6);
      expect(o.remainingAt(now.add(const Duration(seconds: 20))), 0);
      expect(o.job.driverNet, 64);
      expect(nextRideOfferFromJob({'no': 'id'}, now: now), isNull);
    });

    test('ETAs are shown as sent: pickup already counts the trip', () {
      expect(
        nextRideEtaLine(
          const NextOfferInfo(
            afterJobId: 'A',
            etaToDropoffMin: 4,
            etaToPickupMin: 7,
          ),
        ),
        'ส่งผู้โดยสารเสร็จใน ~4 นาที · ถึงจุดรับใน ~7 นาที',
      );
      expect(
        nextRideEtaLine(
          const NextOfferInfo(
            afterJobId: 'A',
            etaToDropoffMin: 0,
            etaToPickupMin: 7,
          ),
        ),
        'ถึงจุดรับใน ~7 นาที',
      );
    });

    test('job_queued {job_id, job, arrive_by}', () {
      final q = queuedFromFrame({
        'type': 'job_queued',
        'job_id': 'B',
        'job': rideJson('B'),
        'arrive_by': '2026-11-22T03:15:00Z',
      }, null)!;
      expect(q.jobId, 'B');
      expect(q.pickupAddress, 'สยามพารากอน');
      expect(q.bannerTitle, 'งานถัดไป: รับที่ สยามพารากอน');
      expect(q.arriveBy, DateTime.utc(2026, 11, 22, 3, 15));
      expect(q.arriveByLine, startsWith('ไปถึงจุดรับภายใน '));
      expect(queuedFromFrame({'type': 'job_queued'}, null), isNull);
    });

    test('GET /jobs/next: the ride with queued_next.arrive_by', () {
      final q = queuedFromNextRide(
        rideJson(
          'B',
          queuedNext: {
            'driver_id': 'D',
            'eta_min': 7,
            'arrive_by': '2026-11-22T03:15:00.123Z',
          },
        ),
      )!;
      expect(q.jobId, 'B');
      expect(q.arriveBy?.toUtc().minute, 15);
      expect(queuedFromNextRide(null), isNull);
    });

    test('job_unqueued {job_id, reason}', () {
      final u = unqueuedFromFrame({
        'type': 'job_unqueued',
        'job_id': 'B',
        'reason': 'timeout',
      }, null)!;
      expect(u.jobId, 'B');
      expect(u.reason, 'timeout');
      expect(unqueuedFromFrame({'reason': 'timeout'}, null), isNull);
    });

    test('accept answers', () {
      expect(
        nextRideAcceptBodyOutcome({'message': 'job queued', 'queued': true}),
        NextRideAcceptOutcome.queued,
      );
      expect(
        nextRideAcceptBodyOutcome({'message': 'job accepted', 'queued': false}),
        NextRideAcceptOutcome.notQueued,
      );
      expect(
        nextRideAcceptOutcomeOf(
          http(409, {'error': 'x', 'code': 'next_ride_unavailable'}),
        ),
        NextRideAcceptOutcome.unavailable,
      );
      expect(
        nextRideAcceptOutcomeOf(http(409, {'error': 'x', 'code': 'job_taken'})),
        NextRideAcceptOutcome.gone,
      );
      expect(
        nextRideAcceptOutcomeOf(
          http(403, {'error': 'x', 'code': CashJobGate.blockedReason}),
        ),
        NextRideAcceptOutcome.cashBlocked,
      );
      expect(nextRideAcceptOutcomeOf(http(500)), NextRideAcceptOutcome.failed);
      expect(isNoNextRideError(http(404, {'code': 'no_next_ride'})), isTrue);
    });
  });

  group('job_accepted', () {
    test('the queued ride starting is handed over, not a plain accept', () {
      expect(
        isNextRideStart(
          acceptedJobId: 'B',
          queued: true,
          collecting: false,
          currentJobId: 'A',
        ),
        isTrue,
      );
      // Collecting A's fare, another ride accepted: only a next ride can be.
      expect(
        isNextRideStart(
          acceptedJobId: 'B',
          queued: false,
          collecting: true,
          currentJobId: 'A',
        ),
        isTrue,
      );
      // The usual accept echo of the ride on screen.
      expect(
        isNextRideStart(
          acceptedJobId: 'A',
          queued: false,
          collecting: true,
          currentJobId: 'A',
        ),
        isFalse,
      );
      expect(
        isNextRideStart(
          acceptedJobId: 'B',
          queued: false,
          collecting: false,
          currentJobId: null,
        ),
        isFalse,
      );
    });
  });

  group('reasons in Thai', () {
    test('each job_unqueued reason has its own line', () {
      const reasons = [
        'timeout',
        'driver_released',
        'trip_ended',
        'cash_blocked',
        'cancelled',
      ];
      final lines = reasons.map(unqueuedReasonMessage).toList();
      expect(lines.toSet().length, reasons.length);
      expect(unqueuedReasonMessage('timeout'), contains('ไม่ทันเวลา'));
      expect(unqueuedReasonMessage('driver_released'), 'ยกเลิกงานถัดไปแล้ว');
      expect(unqueuedReasonMessage('trip_ended'), contains('สิ้นสุด'));
      expect(unqueuedReasonMessage('cash_blocked'), contains('เงินสด'));
      expect(unqueuedReasonMessage('cancelled'), contains('ผู้โดยสารยกเลิก'));
      expect(unqueuedReasonMessage('new_reason'), 'งานถัดไปถูกยกเลิกแล้ว');
      for (final l in [...lines, unqueuedReasonMessage('')]) {
        expect(l, isNot(contains('_')), reason: 'never the raw code');
      }
    });
  });

  group('never the full offer screen', () {
    test('a next_offer job is a next-ride offer', () {
      expect(isNextRideOffer(rideJson('B', nextOffer: nextOffer)), isTrue);
      expect(isNextRideOffer(rideJson('C')), isFalse);
      expect(isNextRideOffer(null), isFalse);
    });

    test('a tapped offer push is not followed while on a job', () {
      expect(
        offerPushBlocked(AppRoutes.incomingJobNamedPage, onAcceptedJob: true),
        isTrue,
      );
      expect(
        offerPushBlocked(AppRoutes.incomingJobNamedPage, onAcceptedJob: false),
        isFalse,
      );
      expect(offerPushBlocked('/held-fares', onAcceptedJob: true), isFalse);
    });
  });

  group('NextRideController', () {
    late FakeApi api;
    late FakeEffects fx;
    late ProviderContainer c;

    NextRideController ctl() => c.read(nextRideControllerProvider.notifier);
    NextRideState st() => c.read(nextRideControllerProvider);

    Map<String, dynamic> queuedFrame(String id) => {
      'type': 'job_queued',
      'job_id': id,
      'job': rideJson(id),
      'arrive_by': '2026-11-22T03:15:00Z',
    };

    setUp(() {
      api = FakeApi();
      fx = FakeEffects();
      c = ProviderContainer(
        overrides: [
          nextRideApiProvider.overrideWithValue(api),
          nextRideEffectsProvider.overrideWithValue(fx),
        ],
      );
    });

    tearDown(() => c.dispose());

    test('an offer opens the card and rings; a repeat is ignored', () {
      expect(ctl().receiveOffer(rideJson('B', nextOffer: nextOffer)), isTrue);
      expect(st().offer?.jobId, 'B');
      expect(fx.rung, ['B']);
      expect(ctl().receiveOffer(rideJson('B', nextOffer: nextOffer)), isFalse);
      expect(fx.rung, ['B']);
    });

    test('offer → accept (queued:true) → banner', () async {
      ctl().receiveOffer(rideJson('B', nextOffer: nextOffer));
      final out = await ctl().accept();
      expect(out, NextRideAcceptOutcome.queued);
      expect(api.accepted, ['B']);
      expect(st().offer, isNull);
      expect(st().queued?.jobId, 'B');
      expect(st().queued?.pickupAddress, 'สยามพารากอน');
      expect(fx.stops, greaterThan(0), reason: 'the alert stops');
      // job_queued then adds arrive_by.
      ctl().onQueued(queuedFrame('B'), null);
      expect(st().queued?.arriveBy, DateTime.utc(2026, 11, 22, 3, 15));
      // A re-sent offer for the queued ride does not reopen the card.
      expect(ctl().receiveOffer(rideJson('B', nextOffer: nextOffer)), isFalse);
    });

    test(
      'job_queued beating the accept reply still ends on the banner',
      () async {
        ctl().receiveOffer(rideJson('B', nextOffer: nextOffer));
        api.acceptGate = Completer();
        final f = ctl().accept();
        ctl().onQueued(queuedFrame('B'), null);
        expect(st().offer, isNull);
        api.acceptGate!.complete(NextRideAcceptOutcome.queued);
        await f;
        expect(st().queued?.jobId, 'B');
        expect(st().accepting, isFalse);
      },
    );

    test('409 next_ride_unavailable closes the card quietly', () async {
      ctl().receiveOffer(rideJson('B', nextOffer: nextOffer));
      api.acceptOutcome = NextRideAcceptOutcome.unavailable;
      await ctl().accept();
      expect(st().offer, isNull);
      expect(st().queued, isNull);
      expect(fx.toasts, isEmpty);
      expect(fx.rejected, isEmpty);
    });

    test('a failed accept keeps the card for another try', () async {
      ctl().receiveOffer(rideJson('B', nextOffer: nextOffer));
      api.acceptOutcome = NextRideAcceptOutcome.failed;
      await ctl().accept();
      expect(st().offer?.jobId, 'B');
      expect(st().accepting, isFalse);
      expect(fx.toasts.single, 'รับงานไม่สำเร็จ กรุณาลองใหม่');
    });

    test('decline sends WS reject_job for that ride', () {
      ctl().receiveOffer(rideJson('B', nextOffer: nextOffer));
      ctl().decline();
      expect(fx.rejected, ['B']);
      expect(st().offer, isNull);
    });

    test('the window running out declines it', () async {
      final t0 = DateTime(2026, 11, 22, 10);
      var calls = 0;
      // Offer made at t0; by the time the timer is armed, 20 s have passed.
      ctl().clock = () =>
          calls++ == 0 ? t0 : t0.add(const Duration(seconds: 20));
      ctl().receiveOffer(rideJson('B', nextOffer: nextOffer));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fx.rejected, ['B']);
      expect(st().offer, isNull);
    });

    test('job_unqueued drops the banner with the reason in Thai', () async {
      ctl().onQueued(queuedFrame('B'), null);
      ctl().onUnqueued({'job_id': 'X', 'reason': 'timeout'}, null);
      expect(st().queued?.jobId, 'B', reason: 'another ride: ignored');
      expect(fx.toasts, isEmpty);
      ctl().onUnqueued({'job_id': 'B', 'reason': 'cash_blocked'}, null);
      expect(st().queued, isNull);
      expect(fx.toasts, [unqueuedReasonMessage('cash_blocked')]);
    });

    test(
      'ยกเลิกงานถัดไป: unqueue, then the frame adds no second toast',
      () async {
        ctl().onQueued(queuedFrame('B'), null);
        expect(await ctl().unqueue(), isTrue);
        expect(api.unqueued, ['B']);
        expect(st().queued, isNull);
        ctl().onUnqueued({'job_id': 'B', 'reason': 'driver_released'}, null);
        expect(fx.toasts, ['ยกเลิกงานถัดไปแล้ว']);
      },
    );

    test('unqueue 404 no_next_ride: already gone', () async {
      ctl().onQueued(queuedFrame('B'), null);
      api.unqueueError = http(404, {'code': 'no_next_ride'});
      expect(await ctl().unqueue(), isTrue);
      expect(st().queued, isNull);
    });

    test('unqueue failing keeps the banner', () async {
      ctl().onQueued(queuedFrame('B'), null);
      api.unqueueError = http(500);
      expect(await ctl().unqueue(), isFalse);
      expect(st().queued?.jobId, 'B');
      expect(fx.toasts.single, 'ยกเลิกงานถัดไปไม่สำเร็จ กรุณาลองใหม่');
    });

    group('after the trip', () {
      IncomingJobModel ride(String id) =>
          IncomingJobModel.fromJson(rideJson(id));

      test('nothing queued: the usual review / home flow', () async {
        expect(await ctl().handOverAfterTrip(), isNull);
        expect(fx.activeReads, 0);
      });

      test('job_accepted came during the COMPLETED: that ride opens', () async {
        ctl().onQueued(queuedFrame('B'), null);
        ctl().onQueuedRideStarted(ride('B'));
        expect(st().queued, isNull);
        expect(st().started?.jobId, 'B');
        final next = await ctl().handOverAfterTrip();
        expect(next?.jobId, 'B');
        expect(st().started, isNull, reason: 'taken once');
      });

      test('job_accepted right after the reply is waited for', () async {
        ctl().onQueued(queuedFrame('B'), null);
        final f = ctl().handOverAfterTrip();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        ctl().onQueuedRideStarted(ride('B'));
        expect((await f)?.jobId, 'B');
        expect(fx.activeReads, 0);
      });

      test('unqueued at the end (cash_blocked): carry on as usual', () async {
        ctl().onQueued(queuedFrame('B'), null);
        final f = ctl().handOverAfterTrip();
        ctl().onUnqueued({'job_id': 'B', 'reason': 'cash_blocked'}, null);
        expect(await f, isNull);
        expect(fx.activeReads, 0);
      });

      test('no frame: GET /jobs/active decides', () async {
        ctl().onQueued(queuedFrame('B'), null);
        fx.active = ride('B');
        final next = await ctl().handOverAfterTrip(
          wait: const Duration(milliseconds: 20),
        );
        expect(next?.jobId, 'B');
        expect(st().queued, isNull);
      });

      test('no frame and the backend holds something else: as usual', () async {
        ctl().onQueued(queuedFrame('B'), null);
        fx.active = null;
        expect(
          await ctl().handOverAfterTrip(wait: const Duration(milliseconds: 20)),
          isNull,
        );
      });

      test(
        'a GET /jobs/next 404 mid hand-over does not drop the ride',
        () async {
          ctl().onQueued(queuedFrame('B'), null);
          final f = ctl().handOverAfterTrip();
          api.next = null;
          await ctl().refresh(onTripJobId: 'A');
          expect(st().queued?.jobId, 'B');
          ctl().onQueuedRideStarted(ride('B'));
          expect((await f)?.jobId, 'B');
        },
      );

      test('the back office closing trip A leaves the queued ride B', () {
        JobCancellations.instance.debugReset();
        ctl().onQueued(queuedFrame('B'), null);
        JobCancellations.instance.report(
          const JobCancelEvent('A', closedByAdmin: true),
        );
        expect(st().queued?.jobId, 'B');
        expect(ctl().isQueued('B'), isTrue);
        expect(ctl().isQueued('A'), isFalse);
      });
    });

    group('refresh (entry / resume)', () {
      test('GET /jobs/next shows the banner; 404 removes it', () async {
        api.next = rideJson(
          'B',
          queuedNext: {'arrive_by': '2026-11-22T03:15:00Z'},
        );
        await ctl().refresh(onTripJobId: 'A');
        expect(st().queued?.jobId, 'B');
        api.next = null;
        await ctl().refresh(onTripJobId: 'A');
        expect(st().queued, isNull);
      });

      test('a read failure keeps the banner', () async {
        ctl().onQueued(queuedFrame('B'), null);
        api.nextError = http(500);
        await ctl().refresh(onTripJobId: 'A');
        expect(st().queued?.jobId, 'B');
      });

      test('a next-ride offer for this trip comes back as the card', () async {
        fx.offerJob = rideJson('B', nextOffer: nextOffer);
        await ctl().refresh(onTripJobId: 'Z');
        expect(st().offer, isNull, reason: 'made against another trip');
        await ctl().refresh(onTripJobId: 'A');
        expect(st().offer?.jobId, 'B');
      });

      test('an ordinary pending offer is not the card', () async {
        fx.offerJob = rideJson('C');
        await ctl().refresh(onTripJobId: 'A');
        expect(st().offer, isNull);
      });
    });
  });

  group('overlay', () {
    late FakeApi api;
    late FakeEffects fx;

    Future<ProviderContainer> pump(WidgetTester tester) async {
      api = FakeApi();
      fx = FakeEffects();
      final c = ProviderContainer(
        overrides: [
          nextRideApiProvider.overrideWithValue(api),
          nextRideEffectsProvider.overrideWithValue(fx),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(body: NextRideOverlay(onTripJobId: 'A')),
          ),
        ),
      );
      return c;
    }

    testWidgets('the card: pickup, ETAs, net, countdown', (tester) async {
      final c = await pump(tester);
      c
          .read(nextRideControllerProvider.notifier)
          .receiveOffer(rideJson('B', nextOffer: nextOffer));
      await tester.pump();
      expect(find.text('งานถัดไป'), findsOneWidget);
      expect(find.text('รับที่ สยามพารากอน'), findsOneWidget);
      expect(
        find.text('ส่งผู้โดยสารเสร็จใน ~4 นาที · ถึงจุดรับใน ~7 นาที'),
        findsOneWidget,
      );
      expect(find.text('รายได้สุทธิ'), findsOneWidget);
      expect(find.text('฿64'), findsOneWidget);
      expect(find.textContaining('ยกเลิกอัตโนมัติใน'), findsOneWidget);
      await tester.tap(find.text('ไม่รับงานนี้'));
      await tester.pump();
      expect(fx.rejected, ['B']);
      expect(find.text('งานถัดไป'), findsNothing);
    });

    testWidgets('the banner asks before giving the ride up', (tester) async {
      final c = await pump(tester);
      c.read(nextRideControllerProvider.notifier).onQueued({
        'job_id': 'B',
        'job': rideJson('B'),
      }, null);
      await tester.pump();
      expect(find.text('งานถัดไป: รับที่ สยามพารากอน'), findsOneWidget);
      await tester.tap(find.text('ยกเลิกงานถัดไป'));
      await tester.pumpAndSettle();
      expect(find.text('ยกเลิกงานถัดไป?'), findsOneWidget);
      expect(api.unqueued, isEmpty);
      await tester.tap(find.widgetWithText(TextButton, 'ยกเลิกงานถัดไป').last);
      await tester.pumpAndSettle();
      expect(api.unqueued, ['B']);
      expect(find.textContaining('งานถัดไป: รับที่'), findsNothing);
    });
  });
}

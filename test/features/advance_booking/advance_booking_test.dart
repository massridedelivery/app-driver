import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/advance_booking/domain/advance_eligibility.dart';
import 'package:massdrive/features/advance_booking/domain/advance_errors.dart';
import 'package:massdrive/features/advance_booking/domain/advance_no_show.dart';
import 'package:massdrive/features/advance_booking/domain/advance_pushes.dart';
import 'package:massdrive/features/advance_booking/domain/advance_ride.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';

/// A board row as the backend's advanceboard.Ride marshals it.
Map<String, dynamic> _rideJson({bool conflict = false, String? flight}) => {
  'id': 'job-1',
  'vehicle_type_id': 'vt-car',
  'vehicle_type': 'รถยนต์',
  // 06:30 on 23 Nov, Bangkok.
  'scheduled_at': '2026-11-22T23:30:00Z',
  'pickup_lat': 13.69,
  'pickup_lng': 100.75,
  'pickup_address': 'สนามบินสุวรรณภูมิ',
  'dropoff_lat': 13.74,
  'dropoff_lng': 100.53,
  'dropoff_address': 'สยามพารากอน',
  'distance_km': 32.4,
  'duration_min': 41.0,
  'fare': 450.0,
  'advance_booking_fee': 40.0,
  'payment_method': 'CASH',
  'policy': {'version': 2, 'wait_minutes': 45, 'flight_number': ?flight},
  'distance_from_you_km': 3.2,
  'estimated_earnings': {
    'net': 383.97,
    'advance_fee_share': 20.0,
    'commission': 66.03,
  },
  'rules': {
    // Go's RFC3339Nano: nine fractional digits.
    'free_release_until': '2026-11-22T17:30:00.123456789Z',
    'late_release_fee': 50,
    'set_off_from': '2026-11-22T22:30:00Z',
    'set_off_by': '2026-11-22T23:10:00+00:00',
    'wait_minutes': 45,
  },
  'conflict': conflict,
};

DioException _refusal(int status, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/api/driver/advance-jobs/x/claim'),
  response: Response(
    requestOptions: RequestOptions(path: '/api/driver/advance-jobs/x/claim'),
    statusCode: status,
    data: body,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  group('AdvanceRide.fromJson', () {
    test('reads every field the card shows', () {
      final r = AdvanceRide.fromJson(_rideJson(flight: 'TG 661'));
      expect(r.id, 'job-1');
      expect(r.scheduledAt, DateTime.utc(2026, 11, 22, 23, 30));
      expect(r.pickupAddress, 'สนามบินสุวรรณภูมิ');
      expect(r.dropoffAddress, 'สยามพารากอน');
      expect(r.distanceKm, 32.4);
      expect(r.distanceFromYouKm, 3.2);
      expect(r.earnings!.net, 383.97);
      expect(r.earnings!.feeShare, 20);
      expect(r.paymentMethod, 'CASH');
      expect(r.flightNumber, 'TG 661');
      expect(r.isAirport, isTrue);
      expect(r.conflict, isFalse);
      final rules = r.rules!;
      expect(rules.freeReleaseUntil!.isUtc, isTrue);
      expect(
        rules.freeReleaseUntil!.difference(DateTime.utc(2026, 11, 22, 17, 30)),
        lessThan(const Duration(seconds: 1)),
      );
      expect(rules.lateReleaseFee, 50);
      expect(rules.setOffFrom, DateTime.utc(2026, 11, 22, 22, 30));
      expect(rules.setOffBy, DateTime.utc(2026, 11, 22, 23, 10));
      expect(rules.waitMinutes, 45);
    });

    test('no flight, no position, conflict', () {
      final json = _rideJson(conflict: true)..remove('distance_from_you_km');
      final r = AdvanceRide.fromJson(json);
      expect(r.flightNumber, isNull);
      expect(r.distanceFromYouKm, isNull);
      expect(r.conflict, isTrue);
    });

    test('listFrom keeps only ride objects; null body is empty', () {
      expect(AdvanceRide.listFrom(null), isEmpty);
      expect(AdvanceRide.listFrom({'error': 'x'}), isEmpty);
      final list = AdvanceRide.listFrom([_rideJson(), 'junk', null]);
      expect(list, hasLength(1));
    });
  });

  group('Bangkok times', () {
    // 17:00 on 22 Nov in Bangkok.
    final now = DateTime.utc(2026, 11, 22, 10);

    test('clock and day labels follow UTC+7', () {
      final at = DateTime.utc(2026, 11, 22, 23, 30);
      expect(formatBangkokTime(at), '06:30 น.');
      expect(formatBangkokDateTime(at), '23 พ.ย. 06:30 น.');
      expect(formatBangkokDayTime(at, now), 'พรุ่งนี้ 06:30 น.');
      expect(
        formatBangkokDayLabel(DateTime.utc(2026, 11, 22, 16, 59), now),
        'วันนี้',
      );
      // 29 Nov 2026 is a Sunday.
      expect(
        formatBangkokDayLabel(DateTime.utc(2026, 11, 29, 3), now),
        'อา. 29 พ.ย.',
      );
    });

    test('a value with an offset is the same instant', () {
      expect(
        parseAdvanceTime('2026-11-23T06:30:00+07:00'),
        DateTime.utc(2026, 11, 22, 23, 30),
      );
      expect(parseAdvanceTime(''), isNull);
      expect(parseAdvanceTime(null), isNull);
    });

    test('date filter is the Bangkok day', () {
      // 23:30 UTC on the 22nd is already the 23rd in Bangkok.
      final day = bangkokDay(DateTime.utc(2026, 11, 22, 23, 30));
      expect(bangkokDateParam(day), '2026-11-23');
    });
  });

  group('eligibility', () {
    test('parses and explains every reason in Thai', () {
      final e = AdvanceEligibility.fromJson({
        'enabled': true,
        'eligible': false,
        'reasons': [
          'BOARD_OFF',
          'ACCOUNT_INACTIVE',
          'NOT_VERIFIED',
          'LOW_RATING',
          'TOO_FEW_JOBS',
          'NO_VEHICLE_TYPE',
          'SUSPENDED',
        ],
        'suspended_until': '2026-11-25T03:00:00Z',
        'late_releases_30d': 3,
        'max_late_releases': 3,
        'min_rating': 4.7,
        'min_completed_jobs': 50,
        'rating': 4.5,
        'completed_jobs': 12,
      });
      expect(e.eligible, isFalse);
      expect(e.reasonLines, [
        'ขณะนี้ยังไม่เปิดรับงานจองล่วงหน้า',
        'บัญชีของคุณถูกระงับหรือยังไม่เปิดใช้งาน กรุณาติดต่อเจ้าหน้าที่',
        'บัญชียังไม่ผ่านการตรวจสอบเอกสาร',
        'คะแนนของคุณ 4.5 ต่ำกว่าเกณฑ์ 4.7',
        'ต้องวิ่งงานสำเร็จอย่างน้อย 50 งาน (ตอนนี้ 12 งาน)',
        'ยังไม่ได้เลือกประเภทรถที่ให้บริการ',
        'ถูกพักรับงานจองล่วงหน้าถึง 25 พ.ย. 10:00 น. '
            'เพราะคืนงานหลังเวลาฟรีบ่อยเกินไป',
      ]);
      expect(e.needsVehicleType, isTrue);
      expect(
        e.lateReleaseLine,
        'คืนงานหลังเวลาฟรี 3/3 ครั้งใน 30 วัน · '
        'ครบ 3 ครั้งจะถูกพักรับงานจองล่วงหน้า',
      );
    });

    test('never shows a raw code; no warning without late releases', () {
      final e = AdvanceEligibility.fromJson({
        'enabled': true,
        'eligible': true,
        'reasons': <String>[],
        'late_releases_30d': 0,
        'max_late_releases': 3,
      });
      expect(e.eligible, isTrue);
      expect(e.lateReleaseLine, isNull);
      expect(e.reasonText('SOMETHING_NEW'), isNot(contains('SOMETHING_NEW')));
    });
  });

  group('refusal codes', () {
    final ride = AdvanceRide.fromJson(_rideJson());

    test('every claim / start / no-show code has Thai text', () {
      for (final code in [
        'ALREADY_TAKEN',
        'SCHEDULE_CONFLICT',
        'TOO_MANY_CLAIMS',
        'TOO_LATE',
        'VEHICLE_TYPE_NOT_YOURS',
        'NOT_ELIGIBLE',
        'SUSPENDED',
        'BOARD_OFF',
        'NOT_YET',
        'CANNOT_START',
        'NO_SHOW_TOO_EARLY',
        'NOT_AT_PICKUP',
        'NOT_YOUR_RIDE',
        'RIDE_NOT_FOUND',
      ]) {
        final text = advanceErrorText(code, ride: ride);
        expect(text, isNotNull, reason: code);
        expect(text, isNot(contains(code)), reason: code);
      }
      expect(advanceErrorText('ALREADY_TAKEN'), 'มีคนขับรับงานนี้ไปแล้ว');
      // set_off_from 22:30 UTC = 05:30 Bangkok.
      expect(advanceErrorText('NOT_YET', ride: ride), contains('05:30 น.'));
    });

    test('a 409 body becomes the coded exception', () {
      final e = asAdvanceError(
        _refusal(409, {'code': 'SCHEDULE_CONFLICT', 'error': 'x'}),
      );
      expect(e, isA<AdvanceBookingException>());
      final a = e as AdvanceBookingException;
      expect(a.status, 409);
      expect(a.code, 'SCHEDULE_CONFLICT');
      expect(a.staleRide, isFalse);
      expect(a.messageFor(), 'เวลางานนี้ชนกับงานจองที่คุณรับไว้แล้ว');
      expect(
        (asAdvanceError(_refusal(403, {'code': 'SUSPENDED'}))
                as AdvanceBookingException)
            .boardClosed,
        isTrue,
      );
    });

    test('an unknown 4xx code gets a generic line, not the server text', () {
      final a =
          asAdvanceError(
                _refusal(409, {'code': 'NEW_THING', 'error': 'NEW_THING'}),
              )
              as AdvanceBookingException;
      expect(a.messageFor(), 'ทำรายการไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    });
  });

  group('release', () {
    const rules = AdvanceRules(lateReleaseFee: 50);
    final until = DateTime.utc(2026, 11, 22, 17, 30);
    final withUntil = AdvanceRules(freeReleaseUntil: until, lateReleaseFee: 50);

    test('before the free time: "คืนฟรีถึง …"', () {
      final t = releaseTermsAt(withUntil, DateTime.utc(2026, 11, 22, 10));
      expect(t.free, isTrue);
      expect(t.headline, 'คืนฟรีถึง 23 พ.ย. 00:30 น.');
      expect(t.confirmLabel, 'คืนงาน');
    });

    test('after it: the late fee', () {
      final t = releaseTermsAt(withUntil, DateTime.utc(2026, 11, 22, 18));
      expect(t.free, isFalse);
      expect(t.headline, 'คืนตอนนี้มีค่าปรับ ฿50');
      expect(t.chargesFee, isTrue);
      expect(
        t.detail,
        'เลยเวลาคืนฟรี (23 พ.ย. 00:30 น.) แล้ว หักค่าปรับ ฿50 '
        'จากกระเป๋าเงินทันที และนับเป็นการคืนงานช้า',
      );
      expect(t.confirmLabel, 'คืนงาน (ค่าปรับ ฿50)');
    });

    test('a 0 fee: a late release costs nothing, no ฿0 line', () {
      final t = releaseTermsAt(
        AdvanceRules(freeReleaseUntil: until, lateReleaseFee: 0),
        DateTime.utc(2026, 11, 22, 18),
      );
      expect(t.free, isFalse);
      expect(t.chargesFee, isFalse);
      expect(t.headline, 'คืนตอนนี้ไม่มีค่าปรับ');
      expect(t.detail, isNot(contains('฿')));
      expect(t.confirmLabel, 'คืนงาน');
      expect(
        AdvanceReleaseResult.fromJson({
          'free': false,
          'penalty': 0,
          'back_on_board': true,
        }).message,
        isNot(contains('฿')),
      );
    });

    test('no free time in the rules reads as free', () {
      expect(releaseTermsAt(rules, DateTime.utc(2026)).free, isTrue);
    });

    test('result wording', () {
      expect(
        AdvanceReleaseResult.fromJson({
          'free': true,
          'penalty': 0,
          'back_on_board': true,
        }).message,
        'คืนงานแล้ว ไม่มีค่าปรับ · งานกลับไปอยู่บนบอร์ดให้คนขับคนอื่น',
      );
      expect(
        AdvanceReleaseResult.fromJson({
          'free': false,
          'penalty': 33.5,
          'back_on_board': false,
        }).message,
        'คืนงานแล้ว หักค่าปรับ ฿33.50 จากกระเป๋าเงินแล้ว · '
        'ระบบกำลังหาคนขับคนอื่นให้ลูกค้า',
      );
    });
  });

  group('start ("กำลังไป")', () {
    final rules = AdvanceRules(
      setOffFrom: DateTime.utc(2026, 11, 22, 22, 30),
      setOffBy: DateTime.utc(2026, 11, 22, 23, 10),
    );

    test('opens at set_off_from, late after set_off_by', () {
      expect(
        startWindowAt(rules, DateTime.utc(2026, 11, 22, 22, 29)),
        StartWindow.notYet,
      );
      expect(
        startWindowAt(rules, DateTime.utc(2026, 11, 22, 22, 30)),
        StartWindow.open,
      );
      expect(
        startWindowAt(rules, DateTime.utc(2026, 11, 22, 23, 10)),
        StartWindow.open,
      );
      expect(
        startWindowAt(rules, DateTime.utc(2026, 11, 22, 23, 11)),
        StartWindow.late,
      );
      expect(startWindowAt(null, DateTime.utc(2026)), StartWindow.open);
    });

    test('hint names the Bangkok times', () {
      expect(
        startHint(rules, DateTime.utc(2026, 11, 22, 20)),
        'กด "กำลังไป" ได้ตั้งแต่ 23 พ.ย. 05:30 น. · ต้องกดภายใน 06:10 น.',
      );
      expect(
        startHint(rules, DateTime.utc(2026, 11, 22, 22, 45)),
        'กด "กำลังไป" ได้แล้ว · ต้องกดภายใน 06:10 น.',
      );
    });
  });

  group('no-show', () {
    Map<String, dynamic> job({String? arrived, Object? policy}) => {
      'id': 'job-1',
      'status': 'ARRIVED_AT_PICK_UP',
      'is_scheduled': true,
      'scheduled_at': '2026-11-22T23:30:00Z',
      'arrived_at_pickup_at': ?arrived,
      'advance_policy': policy,
    };

    test('not an advance ride → nothing', () {
      expect(AdvanceLiveRide.fromJobJson(job()), isNull);
      expect(
        AdvanceLiveRide.fromJobJson({'id': 'x', 'advance_policy': {}}),
        isNull,
      );
    });

    test('wait counts from the pickup time when the driver came early', () {
      final r = AdvanceLiveRide.fromJobJson(
        job(arrived: '2026-11-22T23:20:00Z', policy: {'wait_minutes': 45}),
      )!;
      expect(r.waitMinutes, 45);
      expect(r.noShowFrom(), DateTime.utc(2026, 11, 23, 0, 15));
      expect(r.noShowOpenAt(DateTime.utc(2026, 11, 23, 0, 14)), isFalse);
      expect(r.noShowOpenAt(DateTime.utc(2026, 11, 23, 0, 15)), isTrue);
    });

    test('…and from the arrival when the driver came late', () {
      final r = AdvanceLiveRide.fromJobJson(
        job(arrived: '2026-11-22T23:40:00Z', policy: {'wait_minutes': 10}),
      )!;
      expect(r.noShowFrom(), DateTime.utc(2026, 11, 22, 23, 50));
    });

    test('without the server arrival, the local one is used', () {
      final r = AdvanceLiveRide.fromJobJson(job(policy: {'wait_minutes': 10}))!;
      expect(
        r.noShowFrom(arrivedFallback: DateTime.utc(2026, 11, 22, 23, 45)),
        DateTime.utc(2026, 11, 22, 23, 55),
      );
      expect(r.noShowFrom(), DateTime.utc(2026, 11, 22, 23, 40));
      expect(r.waitingHint(), contains('06:40 น.'));
    });
  });

  group('pushes', () {
    test('current and older advance booking types', () {
      for (final t in [
        'drv_free_release',
        'drv_t60',
        'drv_set_off',
        'advance_job_released',
        'advance_job_cancelled',
        'advance_job_assigned',
        'advance_job_unassigned',
        'advance_booking_drv_t60',
      ]) {
        expect(isAdvanceBookingPush({'type': t}), isTrue, reason: t);
      }
      expect(isAdvanceBookingPush({'type': 'job_cancelled'}), isFalse);
      expect(isAdvanceBookingPush({'type': 'advance_booking_t60'}), isFalse);
      expect(isAdvanceBookingPush({}), isFalse);
    });

    test('the ride is highlighted only while it is still the driver\'s', () {
      for (final t in [
        'drv_free_release',
        'drv_t60',
        'drv_set_off',
        'advance_job_assigned',
      ]) {
        final data = {'type': t, 'job_id': 'job-9', 'route': '/advance-jobs'};
        expect(advancePushHighlight(data), 'job-9', reason: t);
        expect(advanceJobsLocation(data), '/advance-jobs?job=job-9');
      }
      for (final t in [
        'advance_job_released',
        'advance_job_cancelled',
        'advance_job_unassigned',
      ]) {
        final data = {'type': t, 'job_id': 'job-9'};
        expect(advancePushHighlight(data), isNull, reason: t);
        expect(advanceJobsLocation(data), '/advance-jobs');
      }
      expect(advancePushHighlight({'type': 'drv_t60'}), isNull);
      expect(
        advancePushHighlight({'type': 'job_cancelled', 'job_id': 'x'}),
        isNull,
      );
    });
  });
}

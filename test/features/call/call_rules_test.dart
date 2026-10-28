import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/call/domain/call_callability.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/domain/call_models.dart';

void main() {
  group('callErrorOutcome', () {
    test('409 CALL_BUSY: try again later, button stays', () {
      final o = callErrorOutcome(
        const CallError(status: 409, code: 'CALL_BUSY'),
      );
      expect(o.message, 'ลูกค้าไม่ว่าง ลองใหม่อีกครั้ง');
      expect(o.hideButton, isFalse);
      expect(o.refreshSettings, isFalse);
    });

    test('409 CALL_NOT_ALLOWED hides the button', () {
      final o = callErrorOutcome(
        const CallError(status: 409, code: 'CALL_NOT_ALLOWED'),
      );
      expect(o.hideButton, isTrue);
      expect(o.refreshSettings, isFalse);
    });

    test('403 CALL_BLOCKED: "ไม่สามารถโทรได้"', () {
      final o = callErrorOutcome(
        const CallError(status: 403, code: 'CALL_BLOCKED'),
      );
      expect(o.message, 'ไม่สามารถโทรได้');
      expect(o.hideButton, isFalse);
    });

    test('503 CALL_DISABLED hides the button and re-reads the settings', () {
      final o = callErrorOutcome(
        const CallError(status: 503, code: 'CALL_DISABLED'),
      );
      expect(o.hideButton, isTrue);
      expect(o.refreshSettings, isTrue);
    });

    test('404: not this driver\'s order', () {
      final o = callErrorOutcome(const CallError(status: 404));
      expect(o.message, 'ไม่พบงานนี้ในบัญชีของคุณ');
      expect(o.hideButton, isTrue);
    });

    test('no answer at all reads as a connection problem', () {
      expect(
        callErrorOutcome(const CallError()).message,
        contains('อินเทอร์เน็ต'),
      );
    });

    test('anything else is a plain failure, nothing hidden', () {
      final o = callErrorOutcome(const CallError(status: 500));
      expect(o.message, 'โทรไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
      expect(o.hideButton, isFalse);
      expect(o.refreshSettings, isFalse);
    });
  });

  group('isOrderCallable', () {
    final now = DateTime(2026, 10, 28, 12);

    test('ride while it runs', () {
      for (final s in ['ACCEPTED', 'ARRIVED_AT_PICK_UP', 'PICKED_UP']) {
        expect(isOrderCallable(CallKind.ride, s), isTrue, reason: s);
      }
      expect(isOrderCallable(CallKind.ride, 'accepted'), isTrue);
      expect(isOrderCallable(CallKind.ride, 'PENDING'), isFalse);
      expect(isOrderCallable(CallKind.ride, 'CANCELLED'), isFalse);
    });

    test('food: assigned and picked up — not before a driver', () {
      expect(isOrderCallable(CallKind.food, 'DRIVER_ASSIGNED'), isTrue);
      expect(isOrderCallable(CallKind.food, 'DRIVER_PICKED_UP'), isTrue);
      expect(isOrderCallable(CallKind.food, 'PREPARING'), isFalse);
      // A ride status doesn't count for food.
      expect(isOrderCallable(CallKind.food, 'PICKED_UP'), isFalse);
    });

    test('messenger spells arrival ARRIVED_AT_PICKUP', () {
      expect(isOrderCallable(CallKind.messenger, 'ARRIVED_AT_PICKUP'), isTrue);
      expect(
        isOrderCallable(CallKind.messenger, 'ARRIVED_AT_PICK_UP'),
        isFalse,
      );
    });

    test('24h after completion / delivery, not after', () {
      final cases = {
        CallKind.ride: 'COMPLETED',
        CallKind.food: 'DELIVERED',
        CallKind.messenger: 'DELIVERED',
      };
      cases.forEach((kind, done) {
        expect(
          isOrderCallable(
            kind,
            done,
            finishedAt: now.subtract(const Duration(hours: 23, minutes: 59)),
            now: now,
          ),
          isTrue,
          reason: '$kind within 24h',
        );
        expect(
          isOrderCallable(
            kind,
            done,
            finishedAt: now.subtract(const Duration(hours: 24)),
            now: now,
          ),
          isFalse,
          reason: '$kind at 24h',
        );
      });
    });

    test('a finished order without its finish time is not offered', () {
      expect(isOrderCallable(CallKind.ride, 'COMPLETED', now: now), isFalse);
    });

    test('the other kind\'s finished status does not open the window', () {
      expect(
        isOrderCallable(CallKind.ride, 'DELIVERED', finishedAt: now, now: now),
        isFalse,
      );
    });
  });

  group('call payloads', () {
    test('a call view keeps ice_servers as sent', () {
      final v = CallView.fromJson({
        'call_id': 'c',
        'kind': 'food',
        'job_id': 'j',
        'status': 'ringing',
        'peer': {'full_name': 'ก', 'avatar_url': 'u'},
        'ice_servers': [
          {
            'urls': ['turn:t:3478'],
            'username': 'u',
            'credential': 'p',
          },
        ],
        'ring_timeout_sec': 30,
      });
      expect(v.kind, CallKind.food);
      expect(v.peerName, 'ก');
      expect(v.iceServers.single, {
        'urls': ['turn:t:3478'],
        'username': 'u',
        'credential': 'p',
      });
    });

    test('a view without a known kind is rejected', () {
      expect(
        () =>
            CallView.fromJson({'call_id': 'c', 'kind': 'taxi', 'job_id': 'j'}),
        throwsFormatException,
      );
    });

    test('a call push survives the system call UI round trip', () {
      final call = CallInfo.fromPush({
        'type': 'call_incoming',
        'call_id': 'c',
        'kind': 'messenger',
        'job_id': 'j',
        'caller_name': 'ข',
        'caller_avatar': '',
        'ring_timeout_sec': '30',
      })!;
      final back = CallInfo.fromExtra(call.toExtra())!;
      expect(back.kind, CallKind.messenger);
      expect(back.jobId, 'j');
      expect(back.ringTimeoutSec, 30);
      expect(CallInfo.fromPush({'type': 'call_incoming'}), isNull);
    });

    test('a nameless caller shows as ลูกค้า', () {
      const call = CallInfo(callId: 'c', kind: CallKind.ride, jobId: 'j');
      expect(call.displayName, 'ลูกค้า');
    });
  });
}

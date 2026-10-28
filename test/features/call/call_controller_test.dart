import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/call/data/call_pushes.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/domain/call_models.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';
import 'package:massdrive/features/call/domain/call_state.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCallApi api;
  late FakeTransport transport;
  late FakeSystemUi ui;
  late FakeTimers timers;
  late List<FakePeer> peers;
  late ProviderContainer container;

  CallController controller() =>
      container.read(callControllerProvider.notifier);
  CallState state() => container.read(callControllerProvider);

  /// Builds the controller over the fakes and lets its startup run.
  Future<void> boot() async {
    container = ProviderContainer(
      overrides: [
        callApiProvider.overrideWithValue(api),
        callTransportProvider.overrideWithValue(transport),
        callSystemUiProvider.overrideWithValue(ui),
        callPeerFactoryProvider.overrideWithValue((_) async {
          final p = FakePeer();
          peers.add(p);
          return p;
        }),
        callTimerFactoryProvider.overrideWithValue(timers.start),
      ],
    );
    container.listen(callControllerProvider, (_, _) {});
    await pumpEventQueue();
  }

  Future<void> frame(Map<String, dynamic> f) async {
    transport.receive(f);
    await pumpEventQueue();
  }

  Future<void> uiEvent(CallUiAction action, {CallInfo? call}) async {
    ui.uiEvents.add(CallUiEvent(action, call?.callId ?? 'call-1', call: call));
    await pumpEventQueue();
  }

  const incoming = CallInfo(
    callId: 'call-1',
    kind: CallKind.food,
    jobId: 'job-1',
    peerName: 'สมชาย',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeCallApi();
    transport = FakeTransport();
    ui = FakeSystemUi();
    timers = FakeTimers();
    peers = [];
  });

  tearDown(() => container.dispose());

  group('outgoing', () {
    Future<void> placeCall() async {
      await controller().startCall(CallKind.ride, 'job-1', peerName: 'x');
      await pumpEventQueue();
    }

    test('rings, then sends the offer only after call_accepted', () async {
      await boot();
      await placeCall();

      expect(api.calls, ['start:ride:job-1']);
      expect(transport.ensureCount, 1);
      expect(state().phase, CallPhase.outgoingRinging);
      expect(state().call?.displayName, 'สมชาย');
      expect(ui.shownOutgoing, ['call-1']);
      expect(peers, isEmpty);

      await frame({
        'type': 'call_accepted',
        'call': callViewJson(status: 'accepted', withIce: false),
      });
      expect(state().phase, CallPhase.connecting);
      expect(peers, hasLength(1));
      expect(transport.sent.single.kind, 'offer');
      expect(transport.sent.single.callId, 'call-1');

      await frame({
        'type': 'call_signal',
        'call_id': 'call-1',
        'kind': 'answer',
        'payload': {'type': 'answer', 'sdp': 'a'},
      });
      expect(peers.single.log, contains('setRemote:answer'));

      peers.single.peerStates.add(CallPeerState.connected);
      await pumpEventQueue();
      expect(state().phase, CallPhase.connected);
      expect(state().connectedAt, isNotNull);
      expect(ui.connected, ['call-1']);
      // Loudspeaker by default.
      expect(peers.single.speaker, isTrue);
    });

    test('a refusal is rethrown and leaves no call', () async {
      api.startError = const CallError(status: 409, code: 'CALL_BUSY');
      await boot();
      await expectLater(
        controller().startCall(CallKind.ride, 'job-1'),
        throwsA(isA<CallError>()),
      );
      expect(state().phase, CallPhase.idle);
      expect(transport.releaseCount, 1);
      expect(ui.shownOutgoing, isEmpty);
    });

    test(
      'call_ended while ringing (missed) closes it with the reason',
      () async {
        await boot();
        await placeCall();
        await frame({
          'type': 'call_ended',
          'call': callViewJson(status: 'ended', endReason: 'missed'),
        });
        expect(state().phase, CallPhase.ended);
        expect(state().endReason, CallEndReason.missed);
        expect(state().endReason!.suggestsChat, isTrue);
        expect(ui.ended, ['call-1']);
        expect(transport.releaseCount, 1);

        controller().dismiss();
        expect(state().phase, CallPhase.idle);
      },
    );

    test('hanging up while ringing cancels it', () async {
      await boot();
      await placeCall();
      await controller().hangUp();
      expect(api.calls.last, 'end:call-1');
      expect(state().endReason, CallEndReason.cancelled);
    });

    test('a signal for another call is ignored', () async {
      await boot();
      await placeCall();
      await frame({
        'type': 'call_accepted',
        'call': callViewJson(callId: 'other'),
      });
      expect(state().phase, CallPhase.outgoingRinging);
      expect(peers, isEmpty);
    });
  });

  group('incoming', () {
    test('socket call_incoming rings; answering accepts, then answers the '
        'offer', () async {
      await boot();
      await frame({
        'type': 'call_incoming',
        'call': callViewJson(kind: 'food'),
      });
      expect(state().phase, CallPhase.incomingRinging);
      expect(ui.shownIncoming, ['call-1']);
      // The socket's view is current: no extra check.
      expect(api.calls, isEmpty);

      await uiEvent(CallUiAction.accepted, call: incoming);
      expect(api.calls, ['accept:call-1']);
      expect(transport.ensureCount, 1);
      expect(state().phase, CallPhase.connecting);
      expect(state().outgoing, isFalse);
      expect(transport.sent, isEmpty);

      await frame({
        'type': 'call_signal',
        'call_id': 'call-1',
        'kind': 'offer',
        'payload': {'type': 'offer', 'sdp': 'o'},
      });
      expect(transport.sent.single.kind, 'answer');
    });

    test(
      'a push rings, then is dropped when the call no longer rings',
      () async {
        api.getCallResult = CallView.fromJson(
          callViewJson(status: 'ended', endReason: 'cancelled'),
        );
        await boot();
        CallPushes.instance.report({
          'type': 'call_incoming',
          ...incoming.toExtra(),
        });
        await pumpEventQueue();
        expect(api.calls, ['get:call-1']);
        expect(ui.ended, ['call-1']);
        expect(state().phase, CallPhase.idle);
      },
    );

    test('answering before the ring check returns keeps the call', () async {
      api.getCallGate = Completer();
      await boot();
      CallPushes.instance.report({
        'type': 'call_incoming',
        ...incoming.toExtra(),
      });
      await pumpEventQueue();
      await uiEvent(CallUiAction.accepted, call: incoming);
      api.getCallGate!.complete(
        CallView.fromJson(callViewJson(status: 'accepted', withIce: false)),
      );
      await pumpEventQueue();
      expect(state().phase, CallPhase.connecting);
      expect(ui.ended, isEmpty);
    });

    test('409 CALL_ENDED on accept just dismisses', () async {
      api.acceptError = const CallError(status: 409, code: 'CALL_ENDED');
      await boot();
      await uiEvent(CallUiAction.incoming, call: incoming);
      await uiEvent(CallUiAction.accepted, call: incoming);
      expect(state().phase, CallPhase.idle);
      expect(ui.ended, ['call-1']);
      expect(peers, isEmpty);
    });

    test('declining tells the backend', () async {
      await boot();
      await uiEvent(CallUiAction.incoming, call: incoming);
      await uiEvent(CallUiAction.declined, call: incoming);
      expect(api.calls.last, 'decline:call-1');
      expect(state().phase, CallPhase.idle);
    });

    test(
      'a call answered before the app ran is picked up at startup',
      () async {
        ui.active = [const SystemCall(incoming, accepted: true)];
        await boot();
        expect(api.calls, ['accept:call-1']);
        expect(state().phase, CallPhase.connecting);
      },
    );

    test('the call_ended push stops the ring', () async {
      await boot();
      await uiEvent(CallUiAction.incoming, call: incoming);
      CallPushes.instance.report({
        'type': 'call_ended',
        'call_id': 'call-1',
        'end_reason': 'cancelled',
      });
      await pumpEventQueue();
      expect(ui.ended, ['call-1']);
      expect(state().phase, CallPhase.idle);
    });
  });

  group('in the call', () {
    /// Outgoing call, answered and connected.
    Future<FakePeer> connectedCall() async {
      await boot();
      await controller().startCall(CallKind.ride, 'job-1');
      await frame({
        'type': 'call_accepted',
        'call': callViewJson(status: 'accepted', withIce: false),
      });
      await frame({
        'type': 'call_signal',
        'call_id': 'call-1',
        'kind': 'answer',
        'payload': {'type': 'answer', 'sdp': 'a'},
      });
      peers.single.peerStates.add(CallPeerState.connected);
      await pumpEventQueue();
      return peers.single;
    }

    test('a drop shows reconnecting and keeps the timer running', () async {
      final peer = await connectedCall();
      final since = state().connectedAt;
      peer.peerStates.add(CallPeerState.disconnected);
      await pumpEventQueue();
      expect(state().phase, CallPhase.reconnecting);

      peer.peerStates.add(CallPeerState.connected);
      await pumpEventQueue();
      expect(state().phase, CallPhase.connected);
      expect(state().connectedAt, since);
    });

    test('a network change makes the caller restart ICE', () async {
      final peer = await connectedCall();
      transport.sent.clear();
      transport.network.add(null);
      await pumpEventQueue();
      expect(peer.log, contains('createOffer(iceRestart)'));
      expect(transport.sent.single.kind, 'offer');
    });

    test('no reconnect within 15s ends the call as failed', () async {
      final peer = await connectedCall();
      peer.peerStates.add(CallPeerState.disconnected);
      await pumpEventQueue();
      timers.fireActive();
      await pumpEventQueue();
      expect(api.calls.last, 'end:call-1:failed');
      expect(state().phase, CallPhase.ended);
      expect(state().endReason, CallEndReason.failed);
      expect(peer.closed, isTrue);
    });

    test('CALL_SIGNAL_REJECTED tears the call down', () async {
      final peer = await connectedCall();
      await frame({
        'type': 'error',
        'code': 'CALL_SIGNAL_REJECTED',
        'data': 'call ended',
      });
      expect(state().phase, CallPhase.ended);
      expect(peer.closed, isTrue);
      expect(ui.ended, ['call-1']);
    });

    test('socket call_ended closes the peer', () async {
      final peer = await connectedCall();
      await frame({
        'type': 'call_ended',
        'call': callViewJson(status: 'ended', endReason: 'hangup'),
      });
      expect(peer.closed, isTrue);
      expect(state().endReason, CallEndReason.hangup);
      // Ended locally already: a second call_ended changes nothing.
      await frame({
        'type': 'call_ended',
        'call': callViewJson(status: 'ended', endReason: 'lost'),
      });
      expect(state().endReason, CallEndReason.hangup);
    });

    test('mute and speaker reach the peer; speaker is remembered', () async {
      final peer = await connectedCall();
      controller().toggleMute();
      await pumpEventQueue();
      expect(state().muted, isTrue);
      expect(peer.muted, isTrue);

      await controller().toggleSpeaker();
      expect(state().speakerOn, isFalse);
      expect(peer.speaker, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('call_speaker_on'), isFalse);
    });

    test('hanging up ends it on the backend', () async {
      final peer = await connectedCall();
      await controller().hangUp();
      await pumpEventQueue();
      expect(api.calls.last, 'end:call-1');
      expect(state().endReason, CallEndReason.hangup);
      expect(peer.closed, isTrue);
    });
  });

  test('the remembered speaker choice is used for the next call', () async {
    SharedPreferences.setMockInitialValues({'call_speaker_on': false});
    await boot();
    expect(state().speakerOn, isFalse);
  });
}

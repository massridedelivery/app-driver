import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';
import 'package:massdrive/features/call/domain/call_session.dart';

import 'call_fakes.dart';

void main() {
  late FakePeer peer;
  late FakeTimers timers;
  late List<(String, Map<String, dynamic>)> sent;
  late List<CallLink> links;
  List<Map<String, dynamic>>? usedIce;

  CallSession session(CallRole role) => CallSession(
    callId: 'call-1',
    role: role,
    createPeer: (ice) async {
      usedIce = ice;
      return peer;
    },
    sendSignal: (kind, payload) => sent.add((kind, payload)),
    onLink: links.add,
    startTimer: timers.start,
  );

  const ice = [
    {
      'urls': ['stun:stun.example:3478'],
    },
  ];
  Map<String, dynamic> candidate(String c) =>
      const CallIceCandidate('', '0', 0).toJson()..['candidate'] = c;

  setUp(() {
    peer = FakePeer();
    timers = FakeTimers();
    sent = [];
    links = [];
    usedIce = null;
  });

  group('caller', () {
    test('sends the offer on start, with the call\'s ice_servers', () async {
      final s = session(CallRole.caller);
      await s.start(ice);

      expect(usedIce, ice);
      expect(peer.log, ['createOffer', 'setLocal:offer']);
      expect(sent.single.$1, 'offer');
      expect(sent.single.$2, {'type': 'offer', 'sdp': 'offer-sdp-1'});
    });

    test('queues ICE until the answer is set, then adds it in order', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      await s.onSignal('ice', candidate('c1'));
      await s.onSignal('ice', candidate('c2'));
      expect(peer.log.where((l) => l.startsWith('addIce')), isEmpty);

      await s.onSignal('answer', {'type': 'answer', 'sdp': 'a'});
      await s.onSignal('ice', candidate('c3'));
      expect(peer.log.skip(2), [
        'setRemote:answer',
        'addIce:c1',
        'addIce:c2',
        'addIce:c3',
      ]);
    });

    test('ignores an offer (only the callee answers)', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      await s.onSignal('offer', {'type': 'offer', 'sdp': 'x'});
      expect(peer.log, ['createOffer', 'setLocal:offer']);
    });

    test('ICE restart sends a new offer; one at a time', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      await s.onSignal('answer', {'type': 'answer', 'sdp': 'a'});
      sent.clear();

      s.restartIce();
      await pumpEventQueue();
      expect(sent.map((m) => m.$1), ['offer']);
      expect(peer.log.last, 'setLocal:offer');
      expect(peer.log, contains('createOffer(iceRestart)'));

      // Another network change while that offer is unanswered waits for it.
      s.restartIce();
      await pumpEventQueue();
      expect(sent, hasLength(1));

      await s.onSignal('answer', {'type': 'answer', 'sdp': 'b'});
      expect(sent.map((m) => m.$1), ['offer', 'offer']);
    });
  });

  group('callee', () {
    test('answers an offer that arrived before start', () async {
      final s = session(CallRole.callee);
      await s.onSignal('ice', candidate('early'));
      await s.onSignal('offer', {'type': 'offer', 'sdp': 'o'});
      expect(sent, isEmpty);

      await s.start(ice);
      expect(peer.log, [
        'setRemote:offer',
        'addIce:early',
        'createAnswer',
        'setLocal:answer',
      ]);
      expect(sent.single.$1, 'answer');
      expect(sent.single.$2, {'type': 'answer', 'sdp': 'answer-sdp'});
    });

    test(
      'answers a renegotiation offer and never restarts ICE itself',
      () async {
        final s = session(CallRole.callee);
        await s.start(ice);
        await s.onSignal('offer', {'type': 'offer', 'sdp': 'o1'});
        s.restartIce();
        await s.onSignal('offer', {'type': 'offer', 'sdp': 'o2'});
        expect(sent.map((m) => m.$1), ['answer', 'answer']);
        expect(peer.log.where((l) => l.startsWith('createOffer')), isEmpty);
      },
    );
  });

  test('trickles local candidates as ice signals', () async {
    final s = session(CallRole.caller);
    await s.start(ice);
    sent.clear();
    peer.candidates.add(const CallIceCandidate('cand', '0', 0));
    await pumpEventQueue();
    expect(sent.single.$1, 'ice');
    expect(sent.single.$2, {
      'candidate': 'cand',
      'sdpMid': '0',
      'sdpMLineIndex': 0,
    });
  });

  group('connect timeout', () {
    test('fails when the audio never connects within 15s', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      expect(timers.active.single.duration, const Duration(seconds: 15));

      timers.fireActive();
      expect(links, [CallLink.failed]);
    });

    test('connecting cancels it', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      peer.peerStates.add(CallPeerState.connected);
      await pumpEventQueue();
      expect(links, [CallLink.connected]);
      expect(timers.active, isEmpty);
    });

    test('a drop shows reconnecting and recovers', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      peer.peerStates
        ..add(CallPeerState.connected)
        ..add(CallPeerState.disconnected);
      await pumpEventQueue();
      expect(links, [CallLink.connected, CallLink.reconnecting]);
      expect(timers.active, hasLength(1));

      peer.peerStates.add(CallPeerState.connected);
      await pumpEventQueue();
      expect(links.last, CallLink.connected);
      expect(timers.active, isEmpty);
    });

    test('a drop that does not recover fails', () async {
      final s = session(CallRole.caller);
      await s.start(ice);
      await s.onSignal('answer', {'type': 'answer', 'sdp': 'a'});
      peer.peerStates
        ..add(CallPeerState.connected)
        ..add(CallPeerState.failed);
      await pumpEventQueue();
      // The caller tries an ICE restart first.
      expect(peer.log, contains('createOffer(iceRestart)'));

      timers.fireActive();
      expect(links, [
        CallLink.connected,
        CallLink.reconnecting,
        CallLink.failed,
      ]);
    });
  });

  test('close tears the peer down and ignores what comes after', () async {
    final s = session(CallRole.callee);
    await s.start(ice);
    await s.close();
    expect(peer.closed, isTrue);
    expect(timers.active, isEmpty);

    await s.onSignal('offer', {'type': 'offer', 'sdp': 'o'});
    peer.peerStates.add(CallPeerState.connected);
    await pumpEventQueue();
    expect(sent, isEmpty);
    expect(links, isEmpty);
  });

  test(
    'closing before the peer is ready closes the new peer at once',
    () async {
      final s = session(CallRole.caller);
      final starting = s.start(ice);
      await s.close();
      await starting;
      expect(peer.closed, isTrue);
      expect(sent, isEmpty);
    },
  );
}

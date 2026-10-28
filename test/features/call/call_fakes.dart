import 'dart:async';

import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/features/call/data/call_api_service.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/domain/call_models.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';

/// A peer connection that records what the signalling did to it.
class FakePeer implements CallPeer {
  final candidates = StreamController<CallIceCandidate>.broadcast();
  final peerStates = StreamController<CallPeerState>.broadcast();
  final log = <String>[];
  bool closed = false;
  bool? muted;
  bool? speaker;
  int _offers = 0;

  @override
  Stream<CallIceCandidate> get localCandidates => candidates.stream;

  @override
  Stream<CallPeerState> get states => peerStates.stream;

  @override
  Future<CallSdp> createOffer({bool iceRestart = false}) async {
    log.add(iceRestart ? 'createOffer(iceRestart)' : 'createOffer');
    return CallSdp('offer', 'offer-sdp-${++_offers}');
  }

  @override
  Future<CallSdp> createAnswer() async {
    log.add('createAnswer');
    return const CallSdp('answer', 'answer-sdp');
  }

  @override
  Future<void> setLocalDescription(CallSdp sdp) async =>
      log.add('setLocal:${sdp.type}');

  @override
  Future<void> setRemoteDescription(CallSdp sdp) async =>
      log.add('setRemote:${sdp.type}');

  @override
  Future<void> addCandidate(CallIceCandidate c) async =>
      log.add('addIce:${c.candidate}');

  @override
  Future<void> setMuted(bool value) async => muted = value;

  @override
  Future<void> setSpeaker(bool on) async => speaker = on;

  @override
  Future<void> close() async => closed = true;
}

class FakeTimer implements Timer {
  FakeTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

/// Hands out [FakeTimer]s that only fire when the test says so.
class FakeTimers {
  final all = <FakeTimer>[];

  Timer start(Duration duration, void Function() callback) {
    final t = FakeTimer(duration, callback);
    all.add(t);
    return t;
  }

  Iterable<FakeTimer> get active => all.where((t) => t.isActive);

  void fireActive() {
    for (final t in active.toList()) {
      t.fire();
    }
  }
}

Map<String, dynamic> callViewJson({
  String callId = 'call-1',
  String kind = 'ride',
  String jobId = 'job-1',
  String status = 'ringing',
  String? endReason,
  bool withIce = true,
}) => {
  'call_id': callId,
  'kind': kind,
  'job_id': jobId,
  'status': status,
  'peer': {'full_name': 'สมชาย', 'avatar_url': 'https://a/1.png'},
  if (withIce)
    'ice_servers': [
      {
        'urls': ['stun:stun.cloudflare.com:3478'],
      },
    ],
  'ring_timeout_sec': 30,
  'end_reason': ?endReason,
};

class FakeCallApi implements CallApiService {
  final calls = <String>[];
  CallError? startError;
  CallError? acceptError;
  CallView? getCallResult;

  /// When set, GET /api/calls/:id waits for it.
  Completer<CallView>? getCallGate;

  @override
  Future<CallSettings> getSettings() async => const CallSettings(enabled: true);

  @override
  Future<CallView> startCall(CallKind kind, String jobId) async {
    calls.add('start:${kind.name}:$jobId');
    if (startError case final e?) throw e;
    return CallView.fromJson(callViewJson(kind: kind.name, jobId: jobId));
  }

  @override
  Future<CallView> getCall(String callId) async {
    calls.add('get:$callId');
    if (getCallGate case final gate?) return gate.future;
    return getCallResult ??
        CallView.fromJson(callViewJson(callId: callId, withIce: false));
  }

  @override
  Future<CallView> accept(String callId) async {
    calls.add('accept:$callId');
    if (acceptError case final e?) throw e;
    return CallView.fromJson(callViewJson(callId: callId, status: 'accepted'));
  }

  @override
  Future<void> decline(String callId) async => calls.add('decline:$callId');

  @override
  Future<void> end(String callId, {String? reason}) async =>
      calls.add(reason == null ? 'end:$callId' : 'end:$callId:$reason');

  @override
  Future<void> registerVoipToken(String token, {required bool sandbox}) async {}

  @override
  Future<void> deleteVoipToken(String token, {required bool sandbox}) async {}
}

class FakeTransport implements CallTransport {
  final socket = StreamController<SocketMessageModel>.broadcast();
  final status = StreamController<bool>.broadcast();
  final network = StreamController<void>.broadcast();
  final sent = <({String callId, String kind, Map<String, dynamic> payload})>[];
  bool connected = true;
  int ensureCount = 0;
  int releaseCount = 0;

  /// Delivers a server frame as the socket service would.
  void receive(Map<String, dynamic> frame) =>
      socket.add(SocketMessageModel.fromJson(frame));

  @override
  Stream<SocketMessageModel> get messages => socket.stream;

  @override
  Stream<bool> get connectionStatus => status.stream;

  @override
  Stream<void> get networkChanges => network.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> ensureConnected() async => ensureCount++;

  @override
  void release() => releaseCount++;

  @override
  void sendSignal(String callId, String kind, Map<String, dynamic> payload) =>
      sent.add((callId: callId, kind: kind, payload: payload));
}

class FakeSystemUi implements CallSystemUi {
  final uiEvents = StreamController<CallUiEvent>.broadcast();
  final shownIncoming = <String>[];
  final shownOutgoing = <String>[];
  final ended = <String>[];
  final connected = <String>[];
  List<SystemCall> active = const [];

  @override
  Stream<CallUiEvent> get events => uiEvents.stream;

  @override
  Future<void> showIncoming(CallInfo call) async =>
      shownIncoming.add(call.callId);

  @override
  Future<void> showOutgoing(CallInfo call) async =>
      shownOutgoing.add(call.callId);

  @override
  Future<void> setConnected(String callId) async => connected.add(callId);

  @override
  Future<void> setMuted(String callId, bool muted) async {}

  @override
  Future<void> end(String callId) async => ended.add(callId);

  @override
  Future<List<SystemCall>> activeCalls() async => active;
}

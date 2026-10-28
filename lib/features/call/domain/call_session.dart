import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';

typedef CallTimerFactory =
    Timer Function(Duration duration, void Function() callback);

enum CallRole { caller, callee }

/// What a [CallSession] tells the call about its audio link.
enum CallLink { connected, reconnecting, failed }

/// The WebRTC handshake of one answered call over the app's WebSocket.
///
/// The caller sends the offer as soon as it starts (it is started on
/// `call_accepted`); the callee answers the offer it receives — signals can be
/// fed in before [start], so an offer that beats the accept response isn't
/// lost. ICE trickles both ways and
/// candidates that arrive before the remote description is set wait in a
/// queue. On a network change the caller renegotiates with an ICE restart —
/// one at a time, never while an offer is unanswered. No connection within
/// [connectTimeout] (first connect, or after a drop) reports
/// [CallLink.failed].
class CallSession {
  CallSession({
    required this.callId,
    required this.role,
    required CallPeerFactory createPeer,
    required void Function(String kind, Map<String, dynamic> payload)
    sendSignal,
    required void Function(CallLink link) onLink,
    this.connectTimeout = const Duration(seconds: 15),
    CallTimerFactory? startTimer,
  }) : _createPeer = createPeer,
       _sendSignal = sendSignal,
       _onLink = onLink,
       _startTimer = startTimer ?? Timer.new;

  final String callId;
  final CallRole role;
  final Duration connectTimeout;

  final CallPeerFactory _createPeer;
  final void Function(String kind, Map<String, dynamic> payload) _sendSignal;
  final void Function(CallLink link) _onLink;
  final CallTimerFactory _startTimer;

  CallPeer? _peer;
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _timer;
  bool _closed = false;
  bool _everConnected = false;
  bool _remoteSet = false;
  bool _awaitingAnswer = false;
  bool _restartPending = false;
  Map<String, dynamic>? _earlyOffer;
  final List<CallIceCandidate> _pendingIce = [];

  /// Signals and renegotiations run one at a time, in arrival order.
  Future<void> _queue = Future.value();

  bool get isClosed => _closed;

  /// Opens the peer connection (microphone on) with the call's
  /// `ice_servers`. Throws when it can't — e.g. the microphone is denied.
  Future<void> start(List<Map<String, dynamic>> iceServers) async {
    if (_closed) return;
    _armTimer();
    final peer = await _createPeer(iceServers);
    if (_closed) {
      await peer.close();
      return;
    }
    _peer = peer;
    _subs
      ..add(
        peer.localCandidates.listen((c) {
          if (!_closed) _sendSignal('ice', c.toJson());
        }),
      )
      ..add(peer.states.listen(_onPeerState));
    if (role == CallRole.caller) {
      await _run(_sendOffer);
    } else if (_earlyOffer case final offer?) {
      _earlyOffer = null;
      await _run(() => _answer(offer));
    }
  }

  /// A `call_signal` from the other phone.
  Future<void> onSignal(String kind, Map<String, dynamic> payload) =>
      _run(() => _handleSignal(kind, payload));

  /// The network changed: the caller renegotiates with a fresh ICE
  /// generation (the callee waits for that offer).
  void restartIce() {
    if (_closed || role != CallRole.caller || _peer == null) return;
    unawaited(
      _run(() async {
        // Checked when the step runs: an offer queued just before may still
        // be waiting for its answer.
        if (_awaitingAnswer) {
          _restartPending = true;
          return;
        }
        await _sendOffer(iceRestart: true);
      }),
    );
  }

  Future<void> setMuted(bool muted) async => _peer?.setMuted(muted);

  Future<void> setSpeaker(bool on) async => _peer?.setSpeaker(on);

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _timer = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _peer?.close();
  }

  Future<void> _run(Future<void> Function() step) {
    final next = _queue.then((_) async {
      if (_closed) return;
      try {
        await step();
      } catch (e) {
        // A bad SDP / candidate from the other side mustn't stop the queue;
        // if the link never comes up the connect timeout ends the call.
        debugPrint('CallSession($callId): signalling step failed: $e');
      }
    });
    _queue = next;
    return next;
  }

  Future<void> _handleSignal(String kind, Map<String, dynamic> payload) async {
    final peer = _peer;
    switch (kind) {
      case 'offer':
        if (role != CallRole.callee) return;
        if (peer == null) {
          _earlyOffer = payload;
          return;
        }
        await _answer(payload);
      case 'answer':
        if (role != CallRole.caller || peer == null) return;
        await peer.setRemoteDescription(CallSdp.fromJson(payload));
        _remoteSet = true;
        _awaitingAnswer = false;
        await _flushIce();
        if (_restartPending) {
          _restartPending = false;
          await _sendOffer(iceRestart: true);
        }
      case 'ice':
        final candidate = CallIceCandidate.fromJson(payload);
        if (peer == null || !_remoteSet) {
          _pendingIce.add(candidate);
        } else {
          await peer.addCandidate(candidate);
        }
    }
  }

  Future<void> _sendOffer({bool iceRestart = false}) async {
    final peer = _peer!;
    final offer = await peer.createOffer(iceRestart: iceRestart);
    await peer.setLocalDescription(offer);
    _awaitingAnswer = true;
    _sendSignal('offer', offer.toJson());
  }

  Future<void> _answer(Map<String, dynamic> offer) async {
    final peer = _peer!;
    await peer.setRemoteDescription(CallSdp.fromJson(offer));
    _remoteSet = true;
    await _flushIce();
    final answer = await peer.createAnswer();
    await peer.setLocalDescription(answer);
    _sendSignal('answer', answer.toJson());
  }

  Future<void> _flushIce() async {
    final peer = _peer;
    if (peer == null) return;
    final queued = List.of(_pendingIce);
    _pendingIce.clear();
    for (final c in queued) {
      await peer.addCandidate(c);
    }
  }

  void _onPeerState(CallPeerState s) {
    if (_closed) return;
    switch (s) {
      case CallPeerState.connected:
        _timer?.cancel();
        _timer = null;
        _everConnected = true;
        _onLink(CallLink.connected);
      case CallPeerState.disconnected:
      case CallPeerState.failed:
        if (_everConnected) _onLink(CallLink.reconnecting);
        _armTimer();
        if (s == CallPeerState.failed) restartIce();
      case CallPeerState.connecting:
      case CallPeerState.closed:
        break;
    }
  }

  /// One timer covers both the first connect and a reconnect.
  void _armTimer() {
    _timer ??= _startTimer(connectTimeout, () {
      _timer = null;
      if (!_closed) _onLink(CallLink.failed);
    });
  }
}

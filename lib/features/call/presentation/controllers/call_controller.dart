import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/call/data/call_api_service.dart';
import 'package:massdrive/features/call/data/call_pushes.dart';
import 'package:massdrive/features/call/data/callkit_system_ui.dart';
import 'package:massdrive/features/call/data/socket_call_transport.dart';
import 'package:massdrive/features/call/data/webrtc_call_peer.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/domain/call_models.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';
import 'package:massdrive/features/call/domain/call_session.dart';
import 'package:massdrive/features/call/domain/call_state.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'call_controller.g.dart';

// What the call controller runs on — overridden with fakes in tests.

@Riverpod(keepAlive: true)
CallApiService callApi(Ref ref) => getIt<CallApiService>();

@Riverpod(keepAlive: true)
CallTransport callTransport(Ref ref) => SocketCallTransport(
  ref.watch(socketServiceProvider),
  isOnline: () => ref.read(onlineStatusProvider).isOnline,
);

@Riverpod(keepAlive: true)
CallSystemUi callSystemUi(Ref ref) => CallKitSystemUi.instance;

@Riverpod(keepAlive: true)
CallPeerFactory callPeerFactory(Ref ref) => WebRtcCallPeer.create;

@Riverpod(keepAlive: true)
CallTimerFactory callTimerFactory(Ref ref) => Timer.new;

const _speakerPrefKey = 'call_speaker_on';

/// The driver's one call at a time, from ring to hang-up: places calls,
/// takes incoming ones from the socket, pushes and the system call UI, runs
/// the WebRTC [CallSession] once answered, and ends it on `call_ended`, a
/// rejected signal or a link that won't come back.
@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  late CallApiService _api;
  late CallTransport _transport;
  late CallSystemUi _ui;
  late CallPeerFactory _createPeer;
  late CallTimerFactory _startTimer;

  final List<StreamSubscription<Object?>> _subs = [];
  CallSession? _session;

  /// From the start response; `call_accepted` doesn't repeat them.
  List<Map<String, dynamic>> _iceServers = const [];
  bool _placing = false;

  @override
  CallState build() {
    _api = ref.watch(callApiProvider);
    _transport = ref.watch(callTransportProvider);
    _ui = ref.watch(callSystemUiProvider);
    _createPeer = ref.watch(callPeerFactoryProvider);
    _startTimer = ref.watch(callTimerFactoryProvider);

    _subs
      ..add(_transport.messages.listen(_onSocket))
      // The socket came back after a drop (usually a network change).
      ..add(
        _transport.connectionStatus.listen((up) {
          if (up) _restartIceIfLive();
        }),
      )
      ..add(
        _transport.networkChanges.listen((_) {
          if (_transport.isConnected) _restartIceIfLive();
        }),
      )
      ..add(_ui.events.listen(_onUiEvent))
      ..add(CallPushes.instance.pushes.listen(_onPush));
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _subs.clear();
      _session?.close();
    });

    Future.microtask(_init);
    return const CallState();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speaker = prefs.getBool(_speakerPrefKey);
      if (speaker != null) state = state.copyWith(speakerOn: speaker);
    } catch (_) {}
    await _resumeSystemCalls();
  }

  // MARK: - Placing a call

  /// Rings the order's customer and shows the outgoing screen. Throws the
  /// backend's refusal as a [CallError]; does nothing while a call is on.
  Future<void> startCall(
    CallKind kind,
    String jobId, {
    String peerName = '',
  }) async {
    if (_placing || state.isBusy) return;
    _placing = true;
    try {
      // `call_accepted` comes over the socket — have it up before ringing.
      await _transport.ensureConnected();
      final CallView view;
      try {
        view = await _api.startCall(kind, jobId);
      } on CallError {
        _transport.release();
        rethrow;
      }
      _iceServers = view.iceServers;
      final call = CallInfo(
        callId: view.callId,
        kind: view.kind,
        jobId: view.jobId,
        peerName: view.peerName.isNotEmpty ? view.peerName : peerName,
        peerAvatar: view.peerAvatar,
        ringTimeoutSec: view.ringTimeoutSec,
      );
      state = CallState(
        phase: CallPhase.outgoingRinging,
        call: call,
        outgoing: true,
        speakerOn: state.speakerOn,
      );
      unawaited(_ui.showOutgoing(call));
    } finally {
      _placing = false;
    }
  }

  // MARK: - In the call

  /// Hang up — or cancel while ringing, or decline a ringing incoming call.
  Future<void> hangUp() async {
    final call = state.call;
    if (call == null || !state.isBusy) return;
    if (state.phase == CallPhase.incomingRinging) {
      _teardown(CallEndReason.declined);
      await _quietly(() => _api.decline(call.callId));
      return;
    }
    _teardown(
      state.phase == CallPhase.outgoingRinging
          ? CallEndReason.cancelled
          : CallEndReason.hangup,
    );
    await _quietly(() => _api.end(call.callId));
  }

  void toggleMute() {
    final call = state.call;
    if (call == null || !state.isBusy) return;
    final muted = !state.muted;
    state = state.copyWith(muted: muted);
    unawaited(_session?.setMuted(muted));
    unawaited(_ui.setMuted(call.callId, muted));
  }

  Future<void> toggleSpeaker() async {
    final on = !state.speakerOn;
    state = state.copyWith(speakerOn: on);
    unawaited(_session?.setSpeaker(on));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_speakerPrefKey, on);
    } catch (_) {}
  }

  /// The ended call's screen was closed.
  void dismiss() {
    if (state.phase == CallPhase.ended) {
      state = CallState(speakerOn: state.speakerOn);
    }
  }

  // MARK: - Incoming

  Future<void> _onIncoming(
    CallInfo call, {
    required bool verified,
    bool shown = false,
  }) async {
    if (_isCurrent(call.callId) || state.isBusy) return;
    state = CallState(
      phase: CallPhase.incomingRinging,
      call: call,
      speakerOn: state.speakerOn,
    );
    if (!shown) await _ui.showIncoming(call);
    if (verified) return;
    // A push can outlive the ring: ask before letting it ring on.
    bool stillRinging() =>
        _isCurrent(call.callId) && state.phase == CallPhase.incomingRinging;
    try {
      final view = await _api.getCall(call.callId);
      // (Answered meanwhile → it says accepted; that's not a stale ring.)
      if (!view.isRinging && stillRinging()) {
        _onEnded(call.callId, view.endReason);
      }
    } on CallError catch (e) {
      if (e.status == 404 && stillRinging()) _onEnded(call.callId, null);
    }
  }

  /// Answered — from CallKit, the lock screen, a headset or the full-screen
  /// call UI.
  Future<void> _answer(CallInfo? call) async {
    if (call == null) return;
    final ringing =
        _isCurrent(call.callId) && state.phase == CallPhase.incomingRinging;
    if (state.isBusy && !ringing) return;
    state = CallState(
      phase: CallPhase.connecting,
      call: call,
      speakerOn: state.speakerOn,
    );
    // Created now so an offer that beats the accept response is kept.
    final session = _newSession(call.callId, CallRole.callee);
    final CallView view;
    try {
      // The caller's offer comes over the socket right after the accept.
      await _transport.ensureConnected();
      view = await _api.accept(call.callId);
    } on CallError catch (e) {
      if (session != _session) return;
      // 409 CALL_ENDED: it stopped ringing meanwhile — just dismiss.
      _teardown(
        e.code == 'CALL_ENDED' ? CallEndReason.missed : CallEndReason.failed,
        showEnded: e.code != 'CALL_ENDED',
      );
      return;
    }
    if (session != _session) return;
    _start(session, view.iceServers);
  }

  // MARK: - Events

  void _onSocket(SocketMessageModel msg) {
    final raw = msg.raw;
    switch (msg.type) {
      case 'call_incoming':
        final view = _view(raw['call']);
        if (view != null && view.isRinging) {
          unawaited(_onIncoming(CallInfo.fromView(view), verified: true));
        }
      case 'call_accepted':
        final view = _view(raw['call']);
        if (view != null) _onAccepted(view);
      case 'call_ended':
        final view = _view(raw['call']);
        if (view != null) _onEnded(view.callId, view.endReason);
      case 'call_signal':
        final id = raw['call_id']?.toString() ?? '';
        final payload = raw['payload'];
        if (_isCurrent(id) && payload is Map) {
          unawaited(
            _session?.onSignal(
              raw['kind']?.toString() ?? '',
              Map<String, dynamic>.from(payload),
            ),
          );
        }
      case 'error':
        // Not our call any more / the call is over.
        if (raw['code'] == 'CALL_SIGNAL_REJECTED' && _session != null) {
          _teardown(CallEndReason.hangup);
        }
    }
  }

  void _onPush(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'call_incoming':
        final call = CallInfo.fromPush(data);
        if (call != null) unawaited(_onIncoming(call, verified: false));
      case 'call_ended':
        final id = data['call_id']?.toString() ?? '';
        if (id.isNotEmpty) _onEnded(id, data['end_reason']?.toString());
    }
  }

  void _onUiEvent(CallUiEvent e) {
    switch (e.action) {
      case CallUiAction.incoming:
        if (e.call case final call?) {
          unawaited(_onIncoming(call, verified: false, shown: true));
        }
      case CallUiAction.accepted:
        unawaited(
          _answer(e.call ?? (_isCurrent(e.callId) ? state.call : null)),
        );
      case CallUiAction.declined:
        if (_isCurrent(e.callId)) _teardown(CallEndReason.declined);
        unawaited(_quietly(() => _api.decline(e.callId)));
      case CallUiAction.ended:
        if (_isCurrent(e.callId)) unawaited(hangUp());
      case CallUiAction.timedOut:
        if (_isCurrent(e.callId) && state.phase == CallPhase.incomingRinging) {
          _teardown(CallEndReason.missed);
        }
      case CallUiAction.muted:
        if (_isCurrent(e.callId) && state.isBusy && state.muted != e.muted) {
          state = state.copyWith(muted: e.muted);
          unawaited(_session?.setMuted(e.muted));
        }
    }
  }

  /// The customer picked up: send the offer.
  void _onAccepted(CallView view) {
    if (!_isCurrent(view.callId) || state.phase != CallPhase.outgoingRinging) {
      return;
    }
    state = state.copyWith(phase: CallPhase.connecting);
    _start(_newSession(view.callId, CallRole.caller), _iceServers);
  }

  void _onEnded(String callId, String? reason) {
    if (_isCurrent(callId)) {
      _teardown(CallEndReason.fromApi(reason));
    } else {
      // A ring this controller never tracked (e.g. rung by a push).
      unawaited(_ui.end(callId));
    }
  }

  /// Calls the system call UI rang before this isolate was listening — a
  /// push woke the app, or the driver answered on the lock screen.
  Future<void> _resumeSystemCalls() async {
    final List<SystemCall> calls;
    try {
      calls = await _ui.activeCalls();
    } catch (_) {
      return;
    }
    for (final c in calls) {
      if (c.outgoing) {
        // Placed by an app run that is gone; nothing drives it any more.
        unawaited(_ui.end(c.call.callId));
        unawaited(_quietly(() => _api.end(c.call.callId)));
      } else if (c.accepted) {
        await _answer(c.call);
      } else {
        await _onIncoming(c.call, verified: false, shown: true);
      }
    }
  }

  // MARK: - Session

  CallSession _newSession(String callId, CallRole role) {
    late final CallSession session;
    session = CallSession(
      callId: callId,
      role: role,
      createPeer: _createPeer,
      sendSignal: (kind, payload) =>
          _transport.sendSignal(callId, kind, payload),
      onLink: (link) => _onLink(session, link),
      startTimer: _startTimer,
    );
    _session = session;
    return session;
  }

  void _start(CallSession session, List<Map<String, dynamic>> iceServers) {
    session.start(iceServers).catchError((Object e) {
      debugPrint('CallController: could not open the call audio: $e');
      if (session == _session) unawaited(_fail());
    });
  }

  void _onLink(CallSession session, CallLink link) {
    if (session != _session) return;
    switch (link) {
      case CallLink.connected:
        final first = state.connectedAt == null;
        state = state.copyWith(
          phase: CallPhase.connected,
          connectedAt: state.connectedAt ?? DateTime.now(),
        );
        unawaited(session.setSpeaker(state.speakerOn));
        unawaited(session.setMuted(state.muted));
        if (first) unawaited(_ui.setConnected(session.callId));
      case CallLink.reconnecting:
        state = state.copyWith(phase: CallPhase.reconnecting);
      case CallLink.failed:
        unawaited(_fail());
    }
  }

  /// The audio never connected, or dropped for good.
  Future<void> _fail() async {
    final call = state.call;
    _teardown(CallEndReason.failed);
    if (call != null) {
      await _quietly(() => _api.end(call.callId, reason: 'failed'));
    }
  }

  void _restartIceIfLive() {
    if (state.phase == CallPhase.connected ||
        state.phase == CallPhase.reconnecting) {
      _session?.restartIce();
    }
  }

  /// Closes the audio and the system call UI. An ended call whose screen was
  /// showing stays [CallPhase.ended] (the screen says why) until dismissed.
  void _teardown(CallEndReason reason, {bool showEnded = true}) {
    if (!state.isBusy) return;
    final call = state.call;
    final hadScreen = state.hasScreen;
    unawaited(_session?.close());
    _session = null;
    _iceServers = const [];
    if (call != null) unawaited(_ui.end(call.callId));
    _transport.release();
    state = hadScreen && showEnded
        ? state.copyWith(phase: CallPhase.ended, endReason: reason)
        : CallState(speakerOn: state.speakerOn);
  }

  bool _isCurrent(String callId) =>
      callId.isNotEmpty &&
      state.call?.callId.toLowerCase() == callId.toLowerCase();

  CallView? _view(Object? json) {
    if (json is! Map) return null;
    try {
      return CallView.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }

  /// Best-effort calls (the other phone hears it from the backend anyway).
  Future<void> _quietly(Future<void> Function() request) async {
    try {
      await request();
    } catch (e) {
      debugPrint('CallController: $e');
    }
  }
}

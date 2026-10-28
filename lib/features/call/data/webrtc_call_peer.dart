import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';

/// [CallPeer] over flutter_webrtc: one audio-only peer connection with the
/// microphone track. Remote audio plays on its own (no renderer for audio).
class WebRtcCallPeer implements CallPeer {
  WebRtcCallPeer._(this._pc, this._mic);

  final RTCPeerConnection _pc;
  final MediaStream _mic;
  final _candidates = StreamController<CallIceCandidate>.broadcast();
  final _states = StreamController<CallPeerState>.broadcast();

  static const Map<String, dynamic> _audioOnly = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
    'optional': [],
  };

  /// A [CallPeerFactory]: `ice_servers` go in exactly as the backend sent
  /// them. Throws when the microphone can't be opened.
  static Future<CallPeer> create(List<Map<String, dynamic>> iceServers) async {
    final pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });
    final MediaStream mic;
    try {
      mic = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
    } catch (_) {
      await pc.close();
      rethrow;
    }
    for (final track in mic.getAudioTracks()) {
      await pc.addTrack(track, mic);
    }
    final peer = WebRtcCallPeer._(pc, mic);
    pc
      ..onIceCandidate = (c) {
        final candidate = c.candidate;
        if (candidate == null || candidate.isEmpty) return;
        peer._candidates.add(
          CallIceCandidate(candidate, c.sdpMid, c.sdpMLineIndex),
        );
      }
      ..onIceConnectionState = (s) {
        final mapped = switch (s) {
          RTCIceConnectionState.RTCIceConnectionStateConnected ||
          RTCIceConnectionState.RTCIceConnectionStateCompleted =>
            CallPeerState.connected,
          RTCIceConnectionState.RTCIceConnectionStateDisconnected =>
            CallPeerState.disconnected,
          RTCIceConnectionState.RTCIceConnectionStateFailed =>
            CallPeerState.failed,
          RTCIceConnectionState.RTCIceConnectionStateClosed =>
            CallPeerState.closed,
          _ => CallPeerState.connecting,
        };
        peer._states.add(mapped);
      };
    return peer;
  }

  @override
  Stream<CallIceCandidate> get localCandidates => _candidates.stream;

  @override
  Stream<CallPeerState> get states => _states.stream;

  @override
  Future<CallSdp> createOffer({bool iceRestart = false}) async {
    if (iceRestart) await _pc.restartIce();
    return _sdp(await _pc.createOffer(_audioOnly));
  }

  @override
  Future<CallSdp> createAnswer() async =>
      _sdp(await _pc.createAnswer(_audioOnly));

  @override
  Future<void> setLocalDescription(CallSdp sdp) =>
      _pc.setLocalDescription(RTCSessionDescription(sdp.sdp, sdp.type));

  @override
  Future<void> setRemoteDescription(CallSdp sdp) =>
      _pc.setRemoteDescription(RTCSessionDescription(sdp.sdp, sdp.type));

  @override
  Future<void> addCandidate(CallIceCandidate c) =>
      _pc.addCandidate(RTCIceCandidate(c.candidate, c.sdpMid, c.sdpMLineIndex));

  @override
  Future<void> setMuted(bool muted) async {
    for (final track in _mic.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> setSpeaker(bool on) => Helper.setSpeakerphoneOn(on);

  @override
  Future<void> close() async {
    for (final track in _mic.getTracks()) {
      await track.stop();
    }
    await _mic.dispose();
    await _pc.close();
    await _candidates.close();
    await _states.close();
  }

  CallSdp _sdp(RTCSessionDescription d) => CallSdp(d.type ?? '', d.sdp ?? '');
}

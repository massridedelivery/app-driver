import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/features/call/domain/call_models.dart';

/// An SDP offer / answer — `{type, sdp}` on the wire.
class CallSdp {
  const CallSdp(this.type, this.sdp);

  final String type;
  final String sdp;

  factory CallSdp.fromJson(Map<String, dynamic> json) =>
      CallSdp(json['type']?.toString() ?? '', json['sdp']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'type': type, 'sdp': sdp};
}

/// A trickled ICE candidate — `{candidate, sdpMid, sdpMLineIndex}`.
class CallIceCandidate {
  const CallIceCandidate(this.candidate, this.sdpMid, this.sdpMLineIndex);

  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  factory CallIceCandidate.fromJson(Map<String, dynamic> json) =>
      CallIceCandidate(
        json['candidate']?.toString() ?? '',
        json['sdpMid']?.toString(),
        json['sdpMLineIndex'] is num
            ? (json['sdpMLineIndex'] as num).toInt()
            : int.tryParse('${json['sdpMLineIndex']}'),
      );

  Map<String, dynamic> toJson() => {
    'candidate': candidate,
    'sdpMid': sdpMid,
    'sdpMLineIndex': sdpMLineIndex,
  };
}

/// The audio link's state, as the call needs it.
enum CallPeerState { connecting, connected, disconnected, failed, closed }

/// The WebRTC peer connection of one call, with the microphone track already
/// added. Kept behind this interface so the signalling can be tested without
/// the plugin.
abstract class CallPeer {
  Stream<CallIceCandidate> get localCandidates;
  Stream<CallPeerState> get states;

  Future<CallSdp> createOffer({bool iceRestart = false});
  Future<CallSdp> createAnswer();
  Future<void> setLocalDescription(CallSdp sdp);
  Future<void> setRemoteDescription(CallSdp sdp);
  Future<void> addCandidate(CallIceCandidate candidate);
  Future<void> setMuted(bool muted);
  Future<void> setSpeaker(bool on);
  Future<void> close();
}

typedef CallPeerFactory =
    Future<CallPeer> Function(List<Map<String, dynamic>> iceServers);

/// The app's WebSocket as the call sees it: incoming frames, its up/down
/// state, network changes, and `call_signal` out.
abstract class CallTransport {
  Stream<SocketMessageModel> get messages;

  /// true each time the socket (re)connects, false when it drops.
  Stream<bool> get connectionStatus;

  /// Fires on a network change (Wi-Fi ↔ 4G).
  Stream<void> get networkChanges;

  bool get isConnected;

  /// Connects the socket when it isn't (a driver who is offline still gets
  /// and makes calls); [release] undoes that once the call is over.
  Future<void> ensureConnected();
  void release();

  void sendSignal(String callId, String kind, Map<String, dynamic> payload);
}

/// What the system call UI (CallKit on iOS, the full-screen incoming call /
/// ongoing-call notification on Android) reports back.
enum CallUiAction { incoming, accepted, declined, ended, timedOut, muted }

class CallUiEvent {
  const CallUiEvent(this.action, this.callId, {this.call, this.muted = false});

  final CallUiAction action;

  /// Lower-case, as the backend sends it (CallKit upper-cases UUIDs).
  final String callId;

  /// From the call's `extra`, when the event carries it.
  final CallInfo? call;
  final bool muted;
}

/// A call the system call UI is showing, e.g. one a push rang before the app
/// was running.
class SystemCall {
  const SystemCall(this.call, {required this.accepted, this.outgoing = false});

  final CallInfo call;
  final bool accepted;
  final bool outgoing;
}

abstract class CallSystemUi {
  Stream<CallUiEvent> get events;

  /// Rings [call] (no-op when it already rings).
  Future<void> showIncoming(CallInfo call);
  Future<void> showOutgoing(CallInfo call);
  Future<void> setConnected(String callId);
  Future<void> setMuted(String callId, bool muted);
  Future<void> end(String callId);
  Future<List<SystemCall>> activeCalls();
}

import 'package:massdrive/features/call/domain/call_kind.dart';

/// `GET /api/calls/settings`. No call button anywhere while [enabled] is false.
class CallSettings {
  const CallSettings({required this.enabled});

  final bool enabled;

  factory CallSettings.fromJson(Map<String, dynamic> json) =>
      CallSettings(enabled: json['enabled'] == true);
}

/// A call as the backend shows it to this driver (start / get / accept, and
/// the `call` of the `call_incoming` / `call_accepted` / `call_ended` frames).
class CallView {
  const CallView({
    required this.callId,
    required this.kind,
    required this.jobId,
    required this.status,
    this.peerName = '',
    this.peerAvatar = '',
    this.iceServers = const [],
    this.ringTimeoutSec = 30,
    this.endReason,
  });

  final String callId;
  final CallKind kind;
  final String jobId;

  /// `ringing` | `accepted` | `ended`.
  final String status;
  final String peerName;
  final String peerAvatar;

  /// Passed as-is to `RTCPeerConnection({iceServers})`. Only on start and
  /// accept; the TURN credentials last an hour.
  final List<Map<String, dynamic>> iceServers;
  final int ringTimeoutSec;

  /// `hangup` · `declined` · `missed` · `cancelled` · `failed` · `lost`.
  final String? endReason;

  bool get isRinging => status == 'ringing';

  /// Throws [FormatException] without a call id, order id or known kind.
  factory CallView.fromJson(Map<String, dynamic> json) {
    final callId = json['call_id']?.toString() ?? '';
    final jobId = json['job_id']?.toString() ?? '';
    final kind = CallKind.fromApi(json['kind']);
    if (callId.isEmpty || jobId.isEmpty || kind == null) {
      throw FormatException('Not a call view: $json');
    }
    final peer = json['peer'] is Map ? json['peer'] as Map : const {};
    final ice = json['ice_servers'];
    return CallView(
      callId: callId,
      kind: kind,
      jobId: jobId,
      status: json['status']?.toString() ?? '',
      peerName: peer['full_name']?.toString() ?? '',
      peerAvatar: peer['avatar_url']?.toString() ?? '',
      iceServers: ice is List
          ? [for (final s in ice.whereType<Map>()) Map<String, dynamic>.from(s)]
          : const [],
      ringTimeoutSec: _int(json['ring_timeout_sec']) ?? 30,
      endReason: json['end_reason']?.toString(),
    );
  }
}

/// Who is on a call and for which order — what the call screen and the
/// system call UI (CallKit / Android full screen) show. Built from a call
/// view, a call push, or the `extra` the system call UI hands back.
class CallInfo {
  const CallInfo({
    required this.callId,
    required this.kind,
    required this.jobId,
    this.peerName = '',
    this.peerAvatar = '',
    this.ringTimeoutSec = 30,
  });

  final String callId;
  final CallKind kind;
  final String jobId;
  final String peerName;
  final String peerAvatar;
  final int ringTimeoutSec;

  /// The name to show; the customer's, or "ลูกค้า" when the backend sent none.
  String get displayName => peerName.trim().isEmpty ? 'ลูกค้า' : peerName;

  factory CallInfo.fromView(CallView v) => CallInfo(
    callId: v.callId,
    kind: v.kind,
    jobId: v.jobId,
    peerName: v.peerName,
    peerAvatar: v.peerAvatar,
    ringTimeoutSec: v.ringTimeoutSec,
  );

  /// The `call_incoming` push (PushKit JSON / FCM data, all values may be
  /// strings). Null when it isn't a usable call push.
  static CallInfo? fromPush(Map<String, dynamic> data) {
    final callId = data['call_id']?.toString() ?? '';
    final jobId = data['job_id']?.toString() ?? '';
    final kind = CallKind.fromApi(data['kind']);
    if (callId.isEmpty || jobId.isEmpty || kind == null) return null;
    return CallInfo(
      callId: callId,
      kind: kind,
      jobId: jobId,
      peerName: data['caller_name']?.toString() ?? '',
      peerAvatar: data['caller_avatar']?.toString() ?? '',
      ringTimeoutSec: _int(data['ring_timeout_sec']) ?? 30,
    );
  }

  /// Round-trips through the system call UI's `extra` (same keys as the push).
  Map<String, dynamic> toExtra() => {
    'call_id': callId,
    'kind': kind.name,
    'job_id': jobId,
    'caller_name': peerName,
    'caller_avatar': peerAvatar,
    'ring_timeout_sec': ringTimeoutSec,
  };

  static CallInfo? fromExtra(Map<String, dynamic>? extra) =>
      extra == null ? null : fromPush(extra);
}

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

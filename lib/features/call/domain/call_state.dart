import 'package:massdrive/features/call/domain/call_models.dart';

/// idle → outgoingRinging / incomingRinging → connecting → connected ↔
/// reconnecting → ended (→ idle once the call screen is closed).
enum CallPhase {
  idle,
  outgoingRinging,
  incomingRinging,
  connecting,
  connected,
  reconnecting,
  ended,
}

/// Why a call ended (`end_reason`), with what the call screen says about it.
enum CallEndReason {
  hangup('วางสายแล้ว'),
  declined('ลูกค้าไม่สะดวกรับสาย'),
  missed('ลูกค้าไม่ได้รับสาย'),
  cancelled('ยกเลิกการโทรแล้ว'),
  failed('โทรไม่สำเร็จ'),
  lost('สายหลุด');

  const CallEndReason(this.message);

  final String message;

  /// The customer didn't pick up: offer the order's chat instead.
  bool get suggestsChat =>
      this == CallEndReason.missed || this == CallEndReason.declined;

  static CallEndReason fromApi(String? value) => CallEndReason.values
      .firstWhere((r) => r.name == value, orElse: () => CallEndReason.hangup);
}

class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.call,
    this.outgoing = false,
    this.muted = false,
    this.speakerOn = true,
    this.connectedAt,
    this.endReason,
  });

  final CallPhase phase;
  final CallInfo? call;

  /// The driver placed the call (vs answered one).
  final bool outgoing;
  final bool muted;

  /// Loudspeaker; the last choice is remembered (drivers have the phone in a
  /// mount), on by default.
  final bool speakerOn;

  /// When the audio first connected — the in-call timer counts from here and
  /// keeps counting through a reconnect.
  final DateTime? connectedAt;
  final CallEndReason? endReason;

  /// A call is ringing or running — no second one may start.
  bool get isBusy => phase != CallPhase.idle && phase != CallPhase.ended;

  /// The phases the in-call screen shows (incoming ringing is the system
  /// call UI's job).
  bool get hasScreen =>
      phase != CallPhase.idle && phase != CallPhase.incomingRinging;

  CallState copyWith({
    CallPhase? phase,
    bool? muted,
    bool? speakerOn,
    DateTime? connectedAt,
    CallEndReason? endReason,
  }) => CallState(
    phase: phase ?? this.phase,
    call: call,
    outgoing: outgoing,
    muted: muted ?? this.muted,
    speakerOn: speakerOn ?? this.speakerOn,
    connectedAt: connectedAt ?? this.connectedAt,
    endReason: endReason ?? this.endReason,
  );
}

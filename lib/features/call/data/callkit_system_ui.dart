import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:massdrive/features/call/domain/call_models.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';

/// How a call shows in CallKit / on Android's incoming-call screen. iOS reads
/// the same settings from the PushKit push in AppDelegate.swift — keep the
/// two in step.
CallKitParams callKitParamsFor(CallInfo call, {bool outgoing = false}) =>
    CallKitParams(
      id: call.callId,
      nameCaller: call.displayName,
      appName: 'Mass Drive',
      avatar: call.peerAvatar.isEmpty ? null : call.peerAvatar,
      handle: 'ลูกค้า',
      type: 0,
      // The backend times the ring out (call_ended, missed); this is only the
      // fallback for when that frame / push never arrives.
      duration: (call.ringTimeoutSec + 5) * 1000,
      extra: {...call.toExtra(), if (outgoing) 'direction': 'outgoing'},
      // The order's chat gets "📞 สายที่ไม่ได้รับ" from the backend instead.
      missedCallNotification: const NotificationParams(showNotification: false),
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'กำลังโทร',
        callbackText: 'วางสาย',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1E2F38',
        actionColor: '#0D995C',
        textColor: '#ffffff',
        textAccept: 'รับสาย',
        textDecline: 'ปฏิเสธ',
        incomingCallNotificationChannelName: 'สายเรียกเข้า',
        missedCallNotificationChannelName: 'สายที่ไม่ได้รับ',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        // Redialling from Recents isn't supported (calls are per order).
        includesCallsInRecents: false,
        audioSessionMode: 'voiceChat',
        ringtonePath: 'system_ringtone_default',
      ),
    );

/// Rings a `call_incoming` push. Also used by the FCM background isolate, so
/// it needs nothing but the plugin.
Future<void> ringCallFromPush(Map<String, dynamic> data) async {
  final call = CallInfo.fromPush(data);
  if (call != null) await CallKitSystemUi.instance.showIncoming(call);
}

/// Stops a ringing call on the `call_ended` push.
Future<void> endCallFromPush(Map<String, dynamic> data) async {
  final id = data['call_id']?.toString() ?? '';
  if (id.isNotEmpty) await CallKitSystemUi.instance.end(id);
}

/// [CallSystemUi] over flutter_callkit_incoming. A single instance: the
/// plugin's event channel takes one listener only, so every consumer shares
/// [events].
class CallKitSystemUi implements CallSystemUi {
  CallKitSystemUi._();

  static final CallKitSystemUi instance = CallKitSystemUi._();

  /// Calls this app ended itself: the decline / ended event the plugin echoes
  /// for them is not the driver's doing.
  final Set<String> _endedByApp = {};

  late final Stream<CallEvent?> _pluginEvents = FlutterCallkitIncoming.onEvent;

  @override
  late final Stream<CallUiEvent> events = _pluginEvents
      .map(_toUiEvent)
      .where((e) => e != null)
      .cast<CallUiEvent>();

  /// The PushKit token changed (iOS).
  late final Stream<void> voipTokenUpdates = _pluginEvents.where(
    (e) => e is CallEventActionDidUpdateDevicePushTokenVoip,
  );

  CallUiEvent? _toUiEvent(CallEvent? e) {
    CallUiEvent? withParams(CallUiAction action, CallKitParams p) {
      final call = CallInfo.fromExtra(_extra(p.extra));
      final id = (call?.callId ?? p.id).toLowerCase();
      if ((action == CallUiAction.declined || action == CallUiAction.ended) &&
          _endedByApp.remove(id)) {
        return null;
      }
      return CallUiEvent(action, id, call: call);
    }

    return switch (e) {
      CallEventActionCallIncoming(:final callKitParams) => withParams(
        CallUiAction.incoming,
        callKitParams,
      ),
      CallEventActionCallAccept(:final callKitParams) => withParams(
        CallUiAction.accepted,
        callKitParams,
      ),
      CallEventActionCallDecline(:final callKitParams) => withParams(
        CallUiAction.declined,
        callKitParams,
      ),
      CallEventActionCallEnded(:final callKitParams) => withParams(
        CallUiAction.ended,
        callKitParams,
      ),
      CallEventActionCallTimeout(:final id) => CallUiEvent(
        CallUiAction.timedOut,
        id.toLowerCase(),
      ),
      CallEventActionCallToggleMute(:final id, :final isMuted) => CallUiEvent(
        CallUiAction.muted,
        id.toLowerCase(),
        muted: isMuted,
      ),
      _ => null,
    };
  }

  @override
  Future<void> showIncoming(CallInfo call) async {
    // The socket frame and the push can both ring the same call.
    final active = await FlutterCallkitIncoming.activeCalls();
    if (active.any((p) => p.id.toLowerCase() == call.callId.toLowerCase())) {
      return;
    }
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParamsFor(call));
  }

  @override
  Future<void> showOutgoing(CallInfo call) =>
      FlutterCallkitIncoming.startCall(callKitParamsFor(call, outgoing: true));

  @override
  Future<void> setConnected(String callId) =>
      FlutterCallkitIncoming.setCallConnected(callId);

  @override
  Future<void> setMuted(String callId, bool muted) =>
      FlutterCallkitIncoming.muteCall(callId, isMuted: muted);

  @override
  Future<void> end(String callId) async {
    _endedByApp.add(callId.toLowerCase());
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('CallKitSystemUi: endCall failed: $e');
    }
  }

  @override
  Future<List<SystemCall>> activeCalls() async {
    final calls = await FlutterCallkitIncoming.activeCalls();
    return [
      for (final p in calls)
        if (CallInfo.fromExtra(_extra(p.extra)) case final call?)
          SystemCall(
            call,
            accepted: p.isAccepted,
            outgoing: p.extra?['direction'] == 'outgoing',
          ),
    ];
  }

  static Map<String, dynamic>? _extra(Map<dynamic, dynamic>? extra) =>
      extra == null ? null : Map<String, dynamic>.from(extra);
}

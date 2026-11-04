import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Breadcrumbs of one call's steps (start, accepted, offer/answer/ice sent
/// and received, link state, end) in the Crashlytics log, and a non-fatal
/// report when a call fails, so a call that rang but never connected shows
/// where it stopped. Ids and step names only — no audio, SDP or names.
class CallTrail {
  CallTrail._();

  static void step(String callId, String step) {
    final line = 'call ${_short(callId)}: $step';
    if (kDebugMode) {
      debugPrint(line);
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(line);
    } catch (_) {}
  }

  /// A call that ended without its audio ever connecting, or dropped.
  static void failed(String callId, String why) {
    step(callId, 'FAILED $why');
    if (kDebugMode) return;
    try {
      FirebaseCrashlytics.instance.recordError(
        CallFailed(why),
        StackTrace.current,
        reason: 'in-app call ${_short(callId)}',
      );
    } catch (_) {}
  }

  static String _short(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class CallFailed implements Exception {
  CallFailed(this.why);
  final String why;
  @override
  String toString() => 'CallFailed: $why';
}

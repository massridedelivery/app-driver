import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Why the app signed the driver out, in Crashlytics: a breadcrumb for every
/// session event and a non-fatal `SessionEnded` report whenever the app
/// itself ended the session (a refresh refused, a 401, an unreadable token).
/// Drivers sent back to login could not be told apart before. Reasons and
/// request paths only (ids masked) — never a token.
class SessionTrail {
  SessionTrail._();

  static void step(String step) {
    final line = 'session: $step';
    if (kDebugMode) {
      debugPrint(line);
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(line);
    } catch (_) {}
  }

  /// The app ended the session on its own; the driver must sign in again.
  static void ended(String reason) {
    step('ENDED $reason');
    if (kDebugMode) return;
    try {
      FirebaseCrashlytics.instance.recordError(
        SessionEnded(reason),
        StackTrace.current,
        reason: 'signed out by the app',
      );
    } catch (_) {}
  }
}

class SessionEnded implements Exception {
  SessionEnded(this.reason);
  final String reason;
  @override
  String toString() => 'SessionEnded: $reason';
}

/// [path] with its id segments (uuids, numbers, long tokens) as `:id`, so a
/// report groups by endpoint and carries no ids.
String maskedPath(String path) {
  final uri = Uri.tryParse(path);
  final segments = (uri?.path ?? path).split('/');
  final id = RegExp(r'^([0-9a-fA-F-]{16,}|\d+|[A-Za-z0-9_-]{24,})$');
  return segments.map((s) => id.hasMatch(s) ? ':id' : s).join('/');
}

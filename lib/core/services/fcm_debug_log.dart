import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class FcmLogEntry {
  final DateTime time;
  final String message;

  const FcmLogEntry(this.time, this.message);

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'm': message,
      };

  factory FcmLogEntry.fromJson(Map<String, dynamic> json) => FcmLogEntry(
        DateTime.parse(json['t'] as String),
        json['m'] as String,
      );
}

/// On-device FCM activity log: permission status, token, and every
/// register/send/receive/tap event, so a tester can check push health from
/// Settings -> FCM Debug Log without a debugger or device console attached.
///
/// Backed by GetStorage instead of an in-memory list because the background
/// message handler ([firebaseMessagingBackgroundHandler] in
/// push_notification_service.dart) runs in its own isolate and can't share
/// in-memory state with the foreground UI — storage is the only thing both
/// isolates can see.
class FcmDebugLog {
  FcmDebugLog._();

  static const _logKey = 'fcm_debug_log_entries';
  static const _tokenKey = 'fcm_debug_token';
  static const _permissionKey = 'fcm_debug_permission';
  static const _maxEntries = 100;

  static GetStorage? _box;

  static GetStorage _storage() {
    // GetStorage.init() runs early in main()/splash, but the background
    // isolate never runs main() — guard with a fallback box so a debug log
    // call can never crash the caller.
    try {
      return _box ??= GetStorage();
    } catch (_) {
      return GetStorage('fcm_debug_fallback');
    }
  }

  /// Fires an async GetStorage op (write/remove) and swallows any failure.
  /// GetStorage debounces its actual disk flush behind an internal Timer, so
  /// a failure (e.g. no Flutter binding to resolve the storage path, as in a
  /// plain `flutter test`) can surface after this call returns and outside
  /// any Future this code awaits — a synchronous try/catch, or even
  /// `.catchError` on the returned Future, doesn't see it. Running the whole
  /// op in its own error zone catches it regardless of when or how it
  /// surfaces, since a zone-created Timer's callback errors route to that
  /// zone's handler instead of crashing the caller (fatal in tests, where an
  /// unhandled zone error fails whatever test happens to be running then).
  static void _fireAndForget(Future<void> Function() op) {
    runZonedGuarded(
      () => op(),
      (e, _) => debugPrint('FcmDebugLog: write failed: $e'),
    );
  }

  static void log(String message) {
    debugPrint('FCM_LOG: $message');
    _fireAndForget(() async {
      final entries = read();
      entries.insert(0, FcmLogEntry(DateTime.now(), message));
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }
      await _storage().write(_logKey, entries.map((e) => e.toJson()).toList());
    });
  }

  static List<FcmLogEntry> read() {
    try {
      final raw = _storage().read<List>(_logKey) ?? const [];
      return raw
          .cast<Map>()
          .map((e) => FcmLogEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void clear() {
    _fireAndForget(() => _storage().remove(_logKey));
  }

  static void setToken(String? token) {
    _fireAndForget(() => _storage().write(_tokenKey, token));
  }

  static String? get token {
    try {
      return _storage().read<String>(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  static void setPermissionStatus(String status) {
    _fireAndForget(() => _storage().write(_permissionKey, status));
  }

  static String? get permissionStatus {
    try {
      return _storage().read<String>(_permissionKey);
    } catch (_) {
      return null;
    }
  }

  /// Safe prefix for logging a token without risking a substring RangeError
  /// on an unexpectedly short value.
  static String truncate(String value, int length) =>
      value.length <= length ? value : value.substring(0, length);
}

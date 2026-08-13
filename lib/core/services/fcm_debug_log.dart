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

  static void log(String message) {
    debugPrint('FCM_LOG: $message');
    try {
      final entries = read();
      entries.insert(0, FcmLogEntry(DateTime.now(), message));
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }
      _storage().write(_logKey, entries.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('FcmDebugLog: write failed: $e');
    }
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
    try {
      _storage().remove(_logKey);
    } catch (_) {}
  }

  static void setToken(String? token) {
    try {
      _storage().write(_tokenKey, token);
    } catch (_) {}
  }

  static String? get token {
    try {
      return _storage().read<String>(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  static void setPermissionStatus(String status) {
    try {
      _storage().write(_permissionKey, status);
    } catch (_) {}
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

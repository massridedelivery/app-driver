import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Crash and error reports to Firebase Crashlytics (native crashes on iOS
/// and Android, plus every uncaught Flutter/Dart error), so a broken build
/// shows up in the console instead of a driver's message.
///
/// Off in debug builds. A report carries the app version/build, the
/// environment and a SHA-256 of the driver id — never a name or phone number
/// (PDPA).
class CrashReporting {
  CrashReporting._();

  static bool _started = false;

  /// Call once, right after Firebase is up. Never throws.
  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      if (kDebugMode) return;

      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      final info = await PackageInfo.fromPlatform();
      await crashlytics.setCustomKey('app_env', EnvironmentConfig.env);
      await crashlytics.setCustomKey('app_version', info.version);
      await crashlytics.setCustomKey('app_build', info.buildNumber);

      SessionNotifier.instance.addListener(_onSessionChanged);
      await _onSessionChanged();
    } catch (e) {
      debugPrint('CrashReporting: start failed: $e');
    }
  }

  /// Tie reports to the signed-in driver (hashed), and drop that on logout.
  static Future<void> _onSessionChanged() async {
    try {
      final driver = SessionNotifier.instance.isAuthenticated
          ? await _driverId()
          : null;
      await FirebaseCrashlytics.instance.setUserIdentifier(
        driver == null ? '' : hashDriverId(driver),
      );
    } catch (e) {
      debugPrint('CrashReporting: user id failed: $e');
    }
  }

  /// `user_id` from the stored access token (a JWT); null if unreadable.
  static Future<String?> _driverId() async {
    final token = await SecureStorageManager().read(
      SecureStorageKey.accessToken,
    );
    return token == null ? null : driverIdFromJwt(token);
  }
}

/// The `user_id` claim of a JWT, or null.
@visibleForTesting
String? driverIdFromJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    final id = claims is Map ? claims['user_id']?.toString() : null;
    return id == null || id.isEmpty ? null : id;
  } catch (_) {
    return null;
  }
}

/// What Crashlytics sees instead of the driver id.
String hashDriverId(String id) => sha256.convert(utf8.encode(id)).toString();

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/services/fcm_debug_log.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/setting/data/sources/notification_api_service.dart';

/// Resolves the current FCM token, or null when push can't be set up (denied
/// permission, no APNs token yet, no token vended).
typedef TokenSource = Future<String?> Function();

/// Fires whenever FCM rotates the device token.
typedef TokenRefreshes = Stream<String> Function();

/// Hands a token to the backend for the signed-in driver.
typedef TokenSink = Future<void> Function(String token);

/// Keeps the backend's FCM device token in sync with the **current** session.
///
/// Registration is driven by [SessionNotifier] rather than by app startup. The
/// previous splash-only version never ran on a fresh login: the startup
/// controller had already returned "logged out" and been disposed, and login
/// navigates straight to /home without passing through the splash again — so a
/// newly signed-in driver received no push at all until the next cold start
/// (and on Android 13+/iOS was never even shown the permission prompt).
/// Listening to the session covers both paths, and re-registers when a
/// different driver signs in on the same device.
class PushTokenRegistrar {
  PushTokenRegistrar._()
    : _acquireToken = _firebaseToken,
      _tokenRefreshes = _firebaseTokenRefreshes,
      _postToken = _postToBackend;

  /// Builds a registrar over fakes so the session-driven behaviour can be
  /// tested without Firebase or a live backend.
  @visibleForTesting
  PushTokenRegistrar.withSources({
    required TokenSource acquireToken,
    required TokenRefreshes tokenRefreshes,
    required TokenSink postToken,
  }) : _acquireToken = acquireToken,
       _tokenRefreshes = tokenRefreshes,
       _postToken = postToken;

  static final PushTokenRegistrar instance = PushTokenRegistrar._();

  final TokenSource _acquireToken;
  final TokenRefreshes _tokenRefreshes;
  final TokenSink _postToken;

  StreamSubscription<String>? _refreshSub;
  bool _listening = false;
  bool _registering = false;
  String? _registeredToken;

  /// Begin tracking the session. Call once, after Firebase and DI are ready;
  /// repeat calls are no-ops.
  void start() {
    if (_listening) return;
    _listening = true;
    SessionNotifier.instance.addListener(_onSessionChanged);
    // The session can already be authenticated by the time we get here (cold
    // start with a live token), and that flip fires no notification.
    _onSessionChanged();
  }

  /// Re-attempt registration for the signed-in driver. Used when something
  /// that previously blocked it has changed — notably the driver granting
  /// notification permission from system settings, where the first attempt
  /// bailed out with no token. No-op while logged out.
  Future<void> retry() async {
    if (!SessionNotifier.instance.isAuthenticated) return;
    await _register();
  }

  /// Detach from the session. Only needed so tests don't leak listeners onto
  /// the [SessionNotifier] singleton between cases.
  @visibleForTesting
  void stop() {
    if (!_listening) return;
    _listening = false;
    SessionNotifier.instance.removeListener(_onSessionChanged);
    _refreshSub?.cancel();
    _refreshSub = null;
    _registeredToken = null;
  }

  void _onSessionChanged() {
    if (SessionNotifier.instance.isAuthenticated) {
      unawaited(_register());
      return;
    }
    // Logged out: stop mirroring token refreshes onto a session that no longer
    // exists, and forget what we sent so the next sign-in registers again even
    // if FCM hands back the same token (it must be re-bound to the new driver).
    _refreshSub?.cancel();
    _refreshSub = null;
    _registeredToken = null;
  }

  Future<void> _register() async {
    if (_registering) return;
    _registering = true;
    try {
      final token = await _acquireToken();
      if (token == null || token.isEmpty) return;

      // Debug builds print the token so it can be pasted into the Firebase
      // console / an HTTP v1 call to fire a test push at this device. Logged
      // before the POST so it is still available when the backend is down.
      // Anyone holding a token can push to that device, so release builds log
      // only that registration happened.
      if (kDebugMode) {
        debugPrint('FCM_TOKEN: $token');
      }

      await _send(token);

      // FCM tokens rotate (reinstall, restore, invalidation); keep the backend
      // in sync when that happens. Torn down on logout by [_onSessionChanged].
      _refreshSub ??= _tokenRefreshes().listen(
        (refreshed) => unawaited(_sendQuietly(refreshed)),
      );
    } catch (e) {
      debugPrint('FCM Error: $e');
    } finally {
      _registering = false;
    }
  }

  /// Token-refresh path: a failed POST here has no caller to surface it, and an
  /// uncaught async error from a stream listener would crash the zone.
  Future<void> _sendQuietly(String token) async {
    try {
      await _send(token);
    } catch (e) {
      debugPrint('FCM: token refresh register failed: $e');
    }
  }

  Future<void> _send(String token) async {
    // A refresh can land after logout — the token belongs to no session then.
    if (!SessionNotifier.instance.isAuthenticated) return;
    // Unchanged since the last successful POST; skip the round trip.
    if (token == _registeredToken) return;

    await _postToken(token);
    _registeredToken = token;
    debugPrint('FCM: device registered');
  }
}

/// Production [TokenSource]: permission prompt, then the platform token.
Future<String?> _firebaseToken() async {
  final messaging = FirebaseMessaging.instance;

  // Prompts on both platforms, including the Android 13+ POST_NOTIFICATIONS
  // runtime permission that FirebaseMessaging.requestPermission() alone does
  // not reliably raise. iOS additionally needs this authorization before APNs
  // will vend a device token at all.
  final authorizationStatus = await requestNotificationPermission();
  if (authorizationStatus == AuthorizationStatus.denied.name) {
    debugPrint('FCM: notification permission denied');
    return null;
  }

  // On iOS the APNs token must be set before getToken() will succeed. On a
  // cold start it can be momentarily null, so wait briefly for it.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    String? apnsToken;
    for (var i = 0; i < 5 && apnsToken == null; i++) {
      apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (apnsToken == null) {
      debugPrint('FCM: APNs token unavailable, skip register');
      FcmDebugLog.log(
        'APNs token unavailable (Simulator has no real APNs token; '
        'a real device is required)',
      );
      return null;
    }
    FcmDebugLog.log('APNs token obtained');
  }

  final token = await messaging.getToken();
  if (token == null || token.isEmpty) {
    debugPrint('FCM: token unavailable, skip register');
    FcmDebugLog.log('FCM token unavailable, skip register');
    return null;
  }
  FcmDebugLog.setToken(token);
  FcmDebugLog.log('FCM token obtained: ${FcmDebugLog.truncate(token, 24)}...');
  return token;
}

Stream<String> _firebaseTokenRefreshes() {
  return FirebaseMessaging.instance.onTokenRefresh.map((token) {
    FcmDebugLog.log('Token refreshed: ${FcmDebugLog.truncate(token, 24)}...');
    return token;
  });
}

Future<void> _postToBackend(String token) async {
  try {
    await getIt<NotificationApiService>().registerDevice({
      'token': token,
      'platform': defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android',
    });
    FcmDebugLog.setToken(token);
    FcmDebugLog.log('Registered with backend OK');
  } catch (e) {
    FcmDebugLog.log('ERROR registering with backend: $e');
    rethrow;
  }
}

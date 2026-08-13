import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/services/fcm_debug_log.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';
import 'package:massdrive/features/setting/data/sources/notification_api_service.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/router/startup_destination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_controller.g.dart';

@riverpod
class AppStartupController extends _$AppStartupController {
  @override
  Future<StartupResult> build() async {
    // Startup must always produce a destination. Throwing here leaves the
    // splash screen with nowhere to go and the app sits on it forever, so a
    // failed or hung session check falls back to the login flow — the driver
    // can act on that, a frozen splash they cannot.
    bool isLoggedIn;
    try {
      final authState = await ref
          .read(authControllerProvider.future)
          .timeout(const Duration(seconds: 5));
      isLoggedIn = authState.isLogin;
    } catch (e) {
      debugPrint('Startup: session check failed, sending to login: $e');
      return StartupResult.onboarding;
    }

    if (!isLoggedIn) return StartupResult.onboarding;

    // Trigger FCM Registration
    _registerNotificationToken();

    // Kill-and-reopen recovery: on every cold launch, check whether the driver
    // has an in-progress job and route straight to it, regardless of which
    // screen route-restoration would otherwise land on. Bounded so a slow/dead
    // backend never blocks startup.
    try {
      final resume = await resolveActiveJob(ref).timeout(
        const Duration(seconds: 8),
      );
      if (resume != null) {
        return StartupResult(
          StartupDestination.home,
          resumeRoute: resume.route,
          resumeExtra: resume.extra,
        );
      }
    } catch (e) {
      debugPrint('Startup: active-job resolve skipped: $e');
    }

    return StartupResult.home;
  }

  Future<void> _registerNotificationToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Requests the OS permission (Android 13+ POST_NOTIFICATIONS via
      // permission_handler + the iOS/Firebase authorization dialog) so a
      // fresh install — or a session that was restored without ever having
      // been asked — always gets prompted here on first login.
      final authorizationStatus = await requestNotificationPermission();
      if (authorizationStatus == AuthorizationStatus.denied.name) {
        debugPrint('FCM: notification permission denied');
        return;
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
          return;
        }
        FcmDebugLog.log('APNs token obtained');
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM: token unavailable, skip register');
        FcmDebugLog.log('FCM token unavailable, skip register');
        return;
      }
      FcmDebugLog.setToken(fcmToken);
      FcmDebugLog.log('FCM token obtained: ${FcmDebugLog.truncate(fcmToken, 24)}...');

      await _sendTokenToBackend(fcmToken);

      // FCM tokens rotate (reinstall, restore, invalidation); keep the backend
      // in sync when that happens.
      messaging.onTokenRefresh.listen((token) {
        FcmDebugLog.log('Token refreshed: ${FcmDebugLog.truncate(token, 24)}...');
        _sendTokenToBackend(token);
      });
    } catch (e) {
      debugPrint('FCM Error: $e');
      FcmDebugLog.log('ERROR during registration: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    final api = getIt<NotificationApiService>();
    try {
      await api.registerDevice({
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      debugPrint('FCM: device registered: $token');
      FcmDebugLog.setToken(token);
      FcmDebugLog.log('Registered with backend OK');
    } catch (e) {
      FcmDebugLog.log('ERROR registering with backend: $e');
      rethrow;
    }
  }
}

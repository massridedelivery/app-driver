import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/setting/data/sources/notification_api_service.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/router/startup_destination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_controller.g.dart';

@riverpod
class AppStartupController extends _$AppStartupController {
  @override
  Future<StartupDestination> build() async {
    final authState = await ref.read(authControllerProvider.future);
    final isLoggedIn = authState.isLogin;

    if (!isLoggedIn) return StartupDestination.onboarding;

    // Trigger FCM Registration
    _registerNotificationToken();

    return StartupDestination.home;
  }

  Future<void> _registerNotificationToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS requires explicit authorization before APNs will vend a device
      // token; without it getToken() returns null and push never arrives.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
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
          return;
        }
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM: token unavailable, skip register');
        return;
      }

      await _sendTokenToBackend(fcmToken);

      // FCM tokens rotate (reinstall, restore, invalidation); keep the backend
      // in sync when that happens.
      messaging.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
      debugPrint('FCM Error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    final api = getIt<NotificationApiService>();
    await api.registerDevice({
      'token': token,
      'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    });
    debugPrint('FCM: device registered: $token');
  }
}

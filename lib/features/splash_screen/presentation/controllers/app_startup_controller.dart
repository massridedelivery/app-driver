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
    // delay for splash animation
    await Future.delayed(const Duration(milliseconds: 1500));

    final authState = await ref.read(authControllerProvider.future);
    final isLoggedIn = authState.isLogin;

    if (!isLoggedIn) return StartupDestination.onboarding;

    // Trigger FCM Registration
    _registerNotificationToken();

    return StartupDestination.home;
  }

  Future<void> _registerNotificationToken() async {
    try {
      final api = getIt<NotificationApiService>();
      // Placeholder token - in production this comes from FirebaseMessaging.instance.getToken()
      const dummyToken = 'dummy_fcm_token_123456';
      
      await api.registerDevice({
        'token': dummyToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      debugPrint('FCM: Device registered successfully with real API');
    } catch (e) {
      debugPrint('FCM Error: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';
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

    // FCM token registration is not triggered here: it follows the session via
    // PushTokenRegistrar (started in main), which also covers a fresh login —
    // that never comes back through this controller.

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
}

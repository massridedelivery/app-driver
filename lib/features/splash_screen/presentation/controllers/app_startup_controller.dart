import 'package:massdrive/router/startup_destination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_controller.g.dart';

@riverpod
class AppStartupController extends _$AppStartupController {
  @override
  Future<StartupDestination> build() async {
    // mock delay init
    await Future.delayed(const Duration(milliseconds: 300));

    final hasOnboarded = true; // จาก storage
    final isLoggedIn = true; // จาก auth

    if (!hasOnboarded) return StartupDestination.onboarding;
    if (!isLoggedIn) return StartupDestination.onboarding;

    return StartupDestination.home;
  }
}

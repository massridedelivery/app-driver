import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/splash_screen/presentation/controllers/app_startup_controller.dart';
import 'package:massdrive/router/startup_destination.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<StartupDestination>>(appStartupControllerProvider, (
        previous,
        next,
      ) {
        if (_navigated) return;

        next.whenOrNull(
          data: (destination) async {
            _navigated = true;

            // ✅ Splash animation delay
            await Future.delayed(const Duration(seconds: 2));
            if (!mounted) return;

            switch (destination) {
              case StartupDestination.onboarding:
                context.go(AppRoutes.onboardingPath);
                break;

              case StartupDestination.home:
                context.go(AppRoutes.homePath);
                break;
            }
          },
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

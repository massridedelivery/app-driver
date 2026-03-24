import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart'; // This import is used
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/splash_screen/presentation/controllers/app_startup_controller.dart';
import 'package:massdrive/router/startup_destination.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupAsync = ref.watch(appStartupControllerProvider);

    startupAsync.when(
      data: (destination) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          switch (destination) {
            case StartupDestination.onboarding:
              context.go(AppRoutes.loginNamedPage);
              break;
            case StartupDestination.home:
              context.go(AppRoutes.homeNamedPage);
              break;
          }
        });
      },
      loading: () {},
      error: (e, _) => debugPrint('Startup Error: $e'),
    );

    return Scaffold(
      backgroundColor: AppColors.foundationOrange600,
      // From wireframe Aber green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.semanticGrayNeutralBgWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.directions_car, // Placeholder for Aber logo
                size: 64,
                color: AppColors.foundationOrange600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mass Rider',
              style: AppTypography.heading1.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

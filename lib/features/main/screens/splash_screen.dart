import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/main/controllers/splash_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashAsync = ref.watch(splashControllerProvider);

    splashAsync.when(
      data: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AppRoutes.homeNamedPage);
        });
      },
      loading: () {},
      error: (e, _) {
        debugPrint(e.toString());
      },
    );

    return Material(
      color: AppColors.semanticGrayNeutralBorderWhite,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Lottie.asset('assets/animations/splash_screen.json')],
        ),
      ),
    );
  }
}

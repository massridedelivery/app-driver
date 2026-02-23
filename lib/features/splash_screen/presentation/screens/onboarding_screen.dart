import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/enum/links.dart';
import 'package:massdrive/core/managers/deeplink_manager.dart';
import 'package:massdrive/features/splash_screen/presentation/controllers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ref
                .read(onboardingControllerProvider.notifier)
                .completeOnboarding();
          },
          child: const Text('Get Started'),
        ),
      ),
    );
  }
}

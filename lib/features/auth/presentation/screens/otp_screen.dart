import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/auth/presentation/controllers/otp_controller.dart';

class OtpScreen extends ConsumerWidget {
  final String phoneNumber;

  const OtpScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to $phoneNumber',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (state.errorMessage != null)
               Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                     state.errorMessage!, 
                     style: const TextStyle(color: Colors.red), 
                     textAlign: TextAlign.center
                  ),
               ),
            Pinput(
              length: 6,
              onChanged: controller.updateOtp,
              onCompleted: (pin) async {
                final success = await controller.verifyOtp(phoneNumber);
                if (success && context.mounted) {
                  context.go(AppRoutes.homeNamedPage);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final success = await controller.verifyOtp(phoneNumber);
                      if (success && context.mounted) {
                        context.go(AppRoutes.homeNamedPage);
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

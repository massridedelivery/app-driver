import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/auth/presentation/controllers/otp_controller.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends ConsumerWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);
    final bool isOtpValid = state.otpCode.length == 6;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: AppTypography.heading3.copyWith(
        color: AppColors.semanticGrayNeutralFgHigh,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.semanticGrayNeutralBorderLightgray),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.semanticGrayNeutralFgHigh),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.semanticGrayNeutralBorderLightgray),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.semanticErrorBorderHigh),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                            // Assuming default or specific sans font is fine
                            children: [
                              TextSpan(
                                text: 'M',
                                style: AppTypography.heading1.copyWith(
                                  color: AppColors.semanticGrayNeutralFgHigh,
                                ),
                              ),
                              TextSpan(
                                text: 'ass',
                                style: AppTypography.heading2.copyWith(
                                  color: AppColors.foundationOrange600,
                                ),
                              ),
                              TextSpan(
                                text: ' D',
                                style: AppTypography.heading1.copyWith(
                                  color: AppColors.semanticGrayNeutralFgHigh,
                                ),
                              ),
                              TextSpan(
                                text: 'rive',
                                style: AppTypography.heading2.copyWith(
                                  color: AppColors.foundationOrange600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'กรอกรหัสยืนยัน',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.semanticGrayNeutralFgHigh,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'รหัส 6 หลักถูกส่งไปยัง $phoneNumber',
                          style: AppTypography.caption3.copyWith(
                            color: AppColors.semanticGrayNeutralFgHigh,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // OTP Input
                        Center(
                          child: Pinput(
                            length: 6,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: submittedPinTheme,
                            errorPinTheme: errorPinTheme,
                            forceErrorState:
                                state.errorMessage != null &&
                                state.errorMessage!.isNotEmpty,
                            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                            showCursor: true,
                            onChanged: controller.updateOtp,
                            onCompleted: (pin) async {
                              final success = await controller.verifyOtp(phoneNumber);
                              if (success && context.mounted) {
                                context.go(AppRoutes.homeNamedPage);
                              }
                            },
                          ),
                        ),
                        if (state.errorMessage != null &&
                            state.errorMessage!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage!,
                            style: AppTypography.caption3.copyWith(
                              color: AppColors.semanticErrorFgHigh,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const Spacer(),

                        // Bottom Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (state.isLoading || !isOtpValid)
                                ? null
                                : () async {
                                    final success = await controller.verifyOtp(
                                      phoneNumber,
                                    );
                                    if (success && context.mounted) {
                                      context.go(AppRoutes.homeNamedPage);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOtpValid
                                  ? AppColors.semanticGrayNeutralFgHigh
                                  : AppColors.semanticDisabledBgLow,
                              disabledBackgroundColor: AppColors.semanticDisabledBgLow,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'ยืนยัน',
                                    style: AppTypography.caption3.copyWith(
                                      color: isOtpValid
                                          ? AppColors.semanticGrayNeutralFgWhite
                                          : AppColors.semanticDisabledFgOnWhite,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

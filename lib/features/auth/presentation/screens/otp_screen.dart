import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/features/account_restricted/presentation/widgets/account_restricted_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/auth/presentation/controllers/otp_controller.dart';
import 'package:massdrive/features/auth/presentation/widgets/auth_style.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends ConsumerWidget {
  final String phoneNumber;
  final String refId;
  final bool isRegistered;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.refId = '',
    this.isRegistered = true,
  });

  /// Masks the middle of the phone number, keeping the prefix and last three
  /// digits so the user can still recognise it. Display-only.
  String get _maskedPhone {
    final p = phoneNumber;
    if (p.length <= 6) return p;
    final head = p.substring(0, 3);
    final tail = p.substring(p.length - 3);
    return '$head${'•' * (p.length - 6)}$tail';
  }

  /// Last four characters of the reference id. Refs are full UUIDs on some
  /// backends and overflow the subtitle; the tail is enough for a user to read
  /// back over the phone. Verification always sends the complete [refId].
  String get _shortRef =>
      refId.length > 4 ? refId.substring(refId.length - 4) : refId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sign-in refused because the account is suspended: explain + offer a call.
    ref.listen(otpControllerProvider, (prev, next) {
      if (next.errorMessage == accountRestrictedLoginMessage &&
          prev?.errorMessage != accountRestrictedLoginMessage) {
        showAccountRestrictedDialog(context);
      }
    });
    final state = ref.watch(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);
    final bool isOtpValid = state.otpCode.length == 6;
    final bool hasError =
        state.errorMessage != null && state.errorMessage!.isNotEmpty;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTypography.heading3.copyWith(color: AuthColors.textPrimary),
      decoration: BoxDecoration(
        color: AuthColors.fieldFill,
        border: Border.all(color: AuthColors.fieldBorder, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AuthColors.accent, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AuthColors.fieldBorder, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.semanticErrorFgHigh, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      title: 'กรอกรหัส OTP',
                      subtitle:
                          'รหัส 6 หลักส่งไปที่ $_maskedPhone${refId.isNotEmpty ? ' (Ref: $_shortRef)' : ''}',
                      onBack: () => context.pop(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          28,
                          20,
                          16 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // OTP Input
                            Center(
                              child: Pinput(
                                length: 6,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: focusedPinTheme,
                                submittedPinTheme: submittedPinTheme,
                                errorPinTheme: errorPinTheme,
                                forceErrorState: hasError,
                                pinputAutovalidateMode:
                                    PinputAutovalidateMode.onSubmit,
                                showCursor: true,
                                onChanged: controller.updateOtp,
                                onCompleted: (pin) async {
                                  final result = await controller.verifyOtp(
                                    phoneNumber,
                                    isRegistered: isRegistered,
                                    refId: refId,
                                  );
                                  if (!context.mounted) return;
                                  if (result == OtpVerifyResult.home) {
                                    context.go(AppRoutes.homeNamedPage);
                                  } else if (result ==
                                      OtpVerifyResult.registrationChecklist) {
                                    context.go(
                                      AppRoutes
                                          .documentRegistrationChecklistNamedPage,
                                    );
                                  }
                                },
                              ),
                            ),
                            if (hasError) ...[
                              const SizedBox(height: 16),
                              Text(
                                state.errorMessage!,
                                style: AppTypography.caption4.copyWith(
                                  color: AppColors.semanticErrorFgHigh,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const Spacer(),

                            // Bottom Button
                            AuthPrimaryButton(
                              label: 'ยืนยัน',
                              enabled: isOtpValid && !state.isLoading,
                              loading: state.isLoading,
                              onTap: () async {
                                final result = await controller.verifyOtp(
                                  phoneNumber,
                                  isRegistered: isRegistered,
                                  refId: refId,
                                );
                                if (!context.mounted) return;
                                if (result == OtpVerifyResult.home) {
                                  context.go(AppRoutes.homeNamedPage);
                                } else if (result ==
                                    OtpVerifyResult.registrationChecklist) {
                                  context.go(
                                    AppRoutes
                                        .documentRegistrationChecklistNamedPage,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

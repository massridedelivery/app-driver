import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/auth/presentation/controllers/otp_controller.dart';
import 'package:pinput/pinput.dart';

// Neutral slate palette + Mass brand red — matches the MassCustomer auth flow.
const Color _kBg = Color(0xFFF8FAFC);
const Color _kFieldFill = Color(0xFFF1F5F9);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kDisabledBg = Color(0xFFE2E8F0);
const Color _kDisabledText = Color(0xFF94A3B8);
const Color _kBrand = AppColors.foundationRed700; // #DB1439
const Color _kBrandDeep = AppColors.foundationRed800; // #B71130

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);
    final bool isOtpValid = state.otpCode.length == 6;
    final bool hasError =
        state.errorMessage != null && state.errorMessage!.isNotEmpty;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: AppTypography.heading3.copyWith(color: _kTextPrimary),
      decoration: BoxDecoration(
        color: _kFieldFill,
        border: Border.all(color: Colors.transparent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: _kBrand, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: Colors.transparent, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.semanticErrorFgHigh, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kTextPrimary),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Verified-icon header on a soft red circle.
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _kBrand.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: _kBrand,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'กรอกรหัสยืนยัน',
                          textAlign: TextAlign.center,
                          style: AppTypography.heading3.copyWith(
                            color: _kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle — masked phone + optional Ref (last 5 chars
                        // only; the full ref is still sent for verification).
                        Text(
                          'รหัส 6 หลักถูกส่งไปยัง $_maskedPhone${refId.isNotEmpty ? ' (Ref: ${refId.length > 5 ? refId.substring(refId.length - 5) : refId})' : ''}',
                          textAlign: TextAlign.center,
                          style: AppTypography.body1.copyWith(
                            color: _kTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

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
                        _ContinueButton(
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
                                AppRoutes.documentRegistrationChecklistNamedPage,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
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

/// Full-width primary button with the brand gradient when enabled and a flat
/// disabled state, matching the MassCustomer auth style.
class _ContinueButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final Future<void> Function() onTap;

  const _ContinueButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kBrand, _kBrandDeep],
                    )
                  : null,
              color: enabled ? null : _kDisabledBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: _kBrand.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTypography.label2.copyWith(
                        color: enabled ? Colors.white : _kDisabledText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

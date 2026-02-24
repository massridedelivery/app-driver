import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/auth/presentation/controllers/login_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    final bool isPhoneValid = state.phoneNumber.length > 9;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo text
              RichText(
                text: TextSpan(
                  style: TextStyle(
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
              const SizedBox(height: 48),

              // Title
              Text(
                'กรอกเบอร์โทรศัพท์ที่เคยสมัครไว้',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'โปรดเพิ่มหมายเลขโทรศัพท์ของคุณ',
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 32),

              // Phone Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  buildCounter:
                      (
                        BuildContext context, {
                        int? currentLength,
                        int? maxLength,
                        bool? isFocused,
                      }) => null,
                  style: const TextStyle(
                    color: AppColors.semanticGrayNeutralFgHigh,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.phone_sharp,
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                    hintText: 'เบอร์โทรศัพท์',
                    hintStyle: AppTypography.caption3.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                    errorText: state.errorMessage?.isEmpty == true
                        ? null
                        : state.errorMessage,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.semanticGrayNeutralBorderLightgray,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.semanticErrorBorderHigh,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.semanticErrorBorderHigh,
                      ),
                    ),
                  ),
                  onChanged: controller.updatePhone,
                ),
              ),

              const Spacer(),

              // Bottom Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (state.isLoading || !isPhoneValid)
                      ? null
                      : () async {
                          final success = await controller.loginWithPhone();
                          if (success && context.mounted) {
                            context.push(
                              '/otp_screen',
                              extra: state.phoneNumber,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPhoneValid
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
                          'รับรหัสยืนยัน',
                          style: AppTypography.caption3.copyWith(
                            color: isPhoneValid
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
    );
  }
}

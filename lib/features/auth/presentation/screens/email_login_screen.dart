import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/auth/presentation/controllers/email_login_controller.dart';

class EmailLoginScreen extends ConsumerWidget {
  const EmailLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emailLoginControllerProvider);
    final controller = ref.read(emailLoginControllerProvider.notifier);

    final bool isValid = state.email.contains('@') && state.password.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.semanticGrayNeutralFgHigh),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เข้าสู่ระบบด้วยอีเมล',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'โปรดกรอกอีเมลและรหัสผ่านของคุณ',
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 32),
              
              // Email Field
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
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: AppColors.semanticGrayNeutralFgHigh,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                    hintText: 'อีเมล',
                    hintStyle: AppTypography.caption3.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
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
                  ),
                  onChanged: controller.updateEmail,
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Field
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
                  obscureText: true,
                  style: const TextStyle(
                    color: AppColors.semanticGrayNeutralFgHigh,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                    hintText: 'รหัสผ่าน',
                    hintStyle: AppTypography.caption3.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
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
                  ),
                  onChanged: controller.updatePassword,
                ),
              ),
              
              if (state.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    state.errorMessage,
                    style: AppTypography.caption3.copyWith(
                      color: AppColors.semanticErrorBorderHigh,
                    ),
                  ),
                ),

              const Spacer(),

              // Bottom Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (state.isLoading || !isValid)
                      ? null
                      : () async {
                          final success = await controller.loginWithEmail();
                          if (success && context.mounted) {
                            context.go(AppRoutes.homeNamedPage);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid
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
                          'เข้าสู่ระบบ',
                          style: AppTypography.caption3.copyWith(
                            color: isValid
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

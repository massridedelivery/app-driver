import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/auth/presentation/controllers/register_controller.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    final bool isValid = state.fullName.isNotEmpty &&
        state.email.contains('@') &&
        state.phone.length > 9 &&
        state.password.length >= 6;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'สร้างบัญชีคนขับ',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'โปรดกรอกข้อมูลเพื่อลงทะเบียนรับงาน',
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              _buildTextField(
                hintText: 'ชื่อ-นามสกุล',
                icon: Icons.person_outline,
                onChanged: (val) => controller.updateFields(fullName: val),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                hintText: 'อีเมล',
                icon: Icons.email_outlined,
                onChanged: (val) => controller.updateFields(email: val),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone Field
              _buildTextField(
                hintText: 'เบอร์โทรศัพท์',
                icon: Icons.phone_outlined,
                onChanged: (val) => controller.updateFields(phone: val),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                hintText: 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร)',
                icon: Icons.lock_outline,
                onChanged: (val) => controller.updateFields(password: val),
                obscureText: true,
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

              const SizedBox(height: 48),

              // Register Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (state.isLoading || !isValid)
                      ? null
                      : () async {
                          final success = await controller.register();
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
                          'ลงทะเบียน',
                          style: AppTypography.caption3.copyWith(
                            color: isValid
                                ? AppColors.semanticGrayNeutralFgWhite
                                : AppColors.semanticDisabledFgOnWhite,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
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
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.semanticGrayNeutralFgHigh,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
          hintText: hintText,
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
        onChanged: onChanged,
      ),
    );
  }
}

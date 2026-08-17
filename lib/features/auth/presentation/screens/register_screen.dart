import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/auth/presentation/controllers/register_controller.dart';

// Neutral slate palette + Mass brand red — matches the MassCustomer auth flow.
const Color _kBg = Color(0xFFF8FAFC);
const Color _kFieldFill = Color(0xFFF1F5F9);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kDisabledBg = Color(0xFFE2E8F0);
const Color _kDisabledText = Color(0xFF94A3B8);
const Color _kBrand = AppColors.foundationRed700; // #DB1439
const Color _kBrandDeep = AppColors.foundationRed800; // #B71130

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    final bool isValid =
        state.fullName.isNotEmpty &&
        state.email.contains('@') &&
        state.phone.length > 9 &&
        state.password.length >= 6;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'สร้างบัญชีคนขับ',
                style: AppTypography.heading3.copyWith(color: _kTextPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'โปรดกรอกข้อมูลเพื่อลงทะเบียนรับงาน',
                style: AppTypography.body1.copyWith(
                  color: _kTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              _buildTextField(
                label: 'ชื่อ-นามสกุล',
                hintText: 'ชื่อ-นามสกุล',
                onChanged: (val) => controller.updateFields(fullName: val),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),

              // Email Field
              _buildTextField(
                label: 'อีเมล',
                hintText: 'อีเมล',
                onChanged: (val) => controller.updateFields(email: val),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Phone Field
              _buildTextField(
                label: 'เบอร์โทรศัพท์',
                hintText: 'เบอร์โทรศัพท์',
                onChanged: (val) => controller.updateFields(phone: val),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Password Field
              _buildTextField(
                label: 'รหัสผ่าน',
                hintText: 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร)',
                onChanged: (val) => controller.updateFields(password: val),
                obscureText: true,
              ),

              if (state.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    state.errorMessage,
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticErrorFgHigh,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Register Button
              _ContinueButton(
                label: 'ลงทะเบียน',
                enabled: isValid && !state.isLoading,
                loading: state.isLoading,
                onTap: () async {
                  final success = await controller.register();
                  if (success && context.mounted) {
                    context.go(AppRoutes.homeNamedPage);
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTypography.caption4.copyWith(color: _kTextSecondary),
          ),
        ),
        TextField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTypography.body1.copyWith(color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.caption3.copyWith(
              color: _kTextSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: _kFieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBrand, width: 1),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
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

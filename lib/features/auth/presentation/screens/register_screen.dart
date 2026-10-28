import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/auth/presentation/controllers/register_controller.dart';
import 'package:massdrive/features/document_registration/presentation/widgets/registration_ui.dart';

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

    return RegistrationScaffold(
      icon: Icons.person_add_rounded,
      title: 'สร้างบัญชีคนขับ',
      subtitle: 'โปรดกรอกข้อมูลเพื่อลงทะเบียนรับงาน',
      onBack: () => context.pop(),
      bottom: RegistrationPrimaryButton(
        label: 'ลงทะเบียน',
        loading: state.isLoading,
        onPressed: isValid && !state.isLoading
            ? () async {
                final result = await controller.register();
                if (!context.mounted) return;
                switch (result) {
                  case RegisterResult.success:
                    context.go(AppRoutes.homeNamedPage);
                  case RegisterResult.alreadyExists:
                    // A driver account already exists for this phone/email —
                    // send them to login instead (BE 409).
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'เบอร์หรืออีเมลนี้มีบัญชีคนขับอยู่แล้ว เข้าสู่ระบบแทน',
                        ),
                      ),
                    );
                    context.go(AppRoutes.loginNamedPage);
                  case RegisterResult.error:
                    break;
                }
              }
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            context,
            label: 'ชื่อ-นามสกุล',
            hintText: 'ชื่อ-นามสกุล',
            onChanged: (val) => controller.updateFields(fullName: val),
            keyboardType: TextInputType.name,
          ),
          _buildTextField(
            context,
            label: 'อีเมล',
            hintText: 'อีเมล',
            onChanged: (val) => controller.updateFields(email: val),
            keyboardType: TextInputType.emailAddress,
          ),
          _buildTextField(
            context,
            label: 'เบอร์โทรศัพท์',
            hintText: 'เบอร์โทรศัพท์',
            onChanged: (val) => controller.updateFields(phone: val),
            keyboardType: TextInputType.phone,
          ),
          _buildTextField(
            context,
            label: 'รหัสผ่าน',
            hintText: 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร)',
            onChanged: (val) => controller.updateFields(password: val),
            obscureText: true,
          ),
          if (state.errorMessage.isNotEmpty)
            RegistrationErrorText(state.errorMessage),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hintText,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return RegistrationField(
      label: label,
      child: TextField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: registrationInputStyle(context),
        decoration: registrationInputDecoration(context, hint: hintText),
        onChanged: onChanged,
      ),
    );
  }
}

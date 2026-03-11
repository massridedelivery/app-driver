import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/driver_profile_info.dart';
import '../controllers/registration_controller.dart';

class BasicProfileFormScreen extends ConsumerStatefulWidget {
  const BasicProfileFormScreen({super.key});

  @override
  ConsumerState<BasicProfileFormScreen> createState() =>
      _BasicProfileFormScreenState();
}

class _BasicProfileFormScreenState
    extends ConsumerState<BasicProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileInfo = ref.read(registrationControllerProvider).profileInfo;
      if (profileInfo != null) {
        _firstNameController.text = profileInfo.firstName;
        _lastNameController.text = profileInfo.lastName;
        _emailController.text = profileInfo.email;
        _emergencyController.text = profileInfo.emergencyContact ?? '';
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final info = DriverProfileInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        emergencyContact: _emergencyController.text.trim(),
      );

      final success = await ref
          .read(registrationControllerProvider.notifier)
          .updateProfile(info);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'ข้อมูลส่วนตัว',
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.semanticGrayNeutralFgHigh,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildTextField(
              'ชื่อ (First Name)',
              _firstNameController,
              true,
              hint: 'เช่น สมชาย',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'นามสกุล (Last Name)',
              _lastNameController,
              true,
              hint: 'เช่น ใจดี',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'อีเมล (Email)',
              _emailController,
              false,
              keyboardType: TextInputType.emailAddress,
              hint: 'เช่น somchai@email.com',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'เบอร์ติดต่อฉุกเฉิน (Emergency Contact)',
              _emergencyController,
              true,
              keyboardType: TextInputType.phone,
              hint: 'เช่น 0812345678',
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.semanticGrayNeutralFgHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'บันทึก',
                        style: AppTypography.label1.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption2.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.label2.copyWith(
            color: AppColors.semanticGrayNeutralFgMidOnGray,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.label2.copyWith(
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
            filled: true,
            fillColor: AppColors.semanticGrayNeutralBgLightgray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorStyle: AppTypography.caption4.copyWith(
              color: AppColors.foundationRed800,
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'กรุณากรอกข้อมูลให้ครบถ้วน';
            }
            return null;
          },
        ),
      ],
    );
  }
}

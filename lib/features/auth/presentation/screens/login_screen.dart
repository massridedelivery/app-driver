import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/features/account_restricted/presentation/widgets/account_restricted_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/auth/presentation/controllers/login_controller.dart';
import 'package:massdrive/features/auth/presentation/widgets/auth_style.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sign-in refused because the account is suspended: explain + offer a call.
    ref.listen(loginControllerProvider, (prev, next) {
      if (next.errorMessage == accountRestrictedLoginMessage &&
          prev?.errorMessage != accountRestrictedLoginMessage) {
        showAccountRestrictedDialog(context);
      }
    });
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final bool isPhoneValid = isValidThaiPhone(state.phoneNumber);
    // Under the field: the server's refusal (INVALID_PHONE), else the length
    // hint while a number is half typed.
    final phoneError =
        state.phoneError ??
        (state.phoneNumber.isNotEmpty && !isPhoneValid ? thaiPhoneHint : null);
    final error = (state.errorMessage?.isEmpty ?? true)
        ? null
        : state.errorMessage;

    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SingleChildScrollView(
        // Clear the Android nav bar when the form is taller than the screen
        // (padding, not viewPadding: it's 0 while the keyboard is up).
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'ยินดีต้อนรับคนขับ',
              subtitle: 'เข้าสู่ระบบด้วยเบอร์ที่สมัครเป็นคนขับ',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _PhoneField(
                    onChanged: controller.updatePhone,
                    error: phoneError != null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 16),
                    child: Text(
                      phoneError ?? 'เราจะส่งรหัส OTP 6 หลักทาง SMS',
                      key: const ValueKey('phone-helper'),
                      style: AppTypography.caption4.copyWith(
                        color: phoneError != null
                            ? AppColors.semanticErrorFgHigh
                            : AuthColors.textSecondary,
                      ),
                    ),
                  ),
                  AuthPrimaryButton(
                    label: 'ขอรหัส OTP',
                    enabled: isPhoneValid && !state.isLoading,
                    loading: state.isLoading,
                    onTap: () async {
                      final success = await controller.loginWithPhone();
                      if (success && context.mounted) {
                        // Read fresh state AFTER loginWithPhone()
                        // updates refId/isRegistered.
                        final fresh = ref.read(loginControllerProvider);
                        context.push(
                          AppRoutes.otpNamedPage,
                          extra: {
                            'phone': fresh.phoneNumber,
                            'refId': fresh.refId,
                            'isRegistered': fresh.isRegistered,
                          },
                        );
                      }
                    },
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error.replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.semanticErrorFgHigh,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // New drivers sign up through the same OTP: an unregistered
                  // number lands on the registration checklist.
                  Text.rich(
                    TextSpan(
                      text: 'ยังไม่ได้เป็นคนขับ? ',
                      children: [
                        TextSpan(
                          text: 'ขอรหัส OTP เพื่อสมัครได้เลย',
                          style: AppTypography.caption4.copyWith(
                            color: AuthColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption4.copyWith(
                      color: AuthColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined phone input with a floating "เบอร์โทรศัพท์" label and a fixed
/// `+66` prefix. Takes "812345678", "0812345678", "081-234-5678" or a pasted
/// "+66812345678" (at most 10 digits) and reports the local `0XXXXXXXXX`
/// form. Red border when [error].
class _PhoneField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool error;

  const _PhoneField({required this.onChanged, this.error = false});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return TextField(
      keyboardType: TextInputType.phone,
      inputFormatters: const [ThaiPhoneInputFormatter()],
      onChanged: (v) => onChanged(normalizeThaiPhone(v)),
      style: AppTypography.heading4.copyWith(
        color: AuthColors.textPrimary,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: 'เบอร์โทรศัพท์',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTypography.body1.copyWith(color: AuthColors.accent),
        floatingLabelStyle: AppTypography.body1.copyWith(
          color: AuthColors.accent,
        ),
        hintText: '812345678',
        hintStyle: AppTypography.heading4.copyWith(
          color: AuthColors.hint,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Text(
            '+66',
            style: AppTypography.heading4.copyWith(
              color: AuthColors.textPrimary,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        filled: true,
        fillColor: AuthColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border(AuthColors.fieldBorder),
        enabledBorder: border(
          error ? AppColors.semanticErrorFgHigh : AuthColors.fieldBorder,
        ),
        focusedBorder: border(
          error ? AppColors.semanticErrorFgHigh : AuthColors.accent,
        ),
      ),
    );
  }
}

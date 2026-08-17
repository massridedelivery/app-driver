import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/auth/presentation/controllers/login_controller.dart';

/// Real app version read from the bundle, so the footer never goes stale.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

// Neutral slate palette + Mass brand red — matches the MassCustomer auth flow.
const Color _kBg = Color(0xFFF8FAFC);
const Color _kFieldFill = Color(0xFFF1F5F9);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kDisabledBg = Color(0xFFE2E8F0);
const Color _kDisabledText = Color(0xFF94A3B8);
const Color _kBrand = AppColors.foundationRed700; // #DB1439
const Color _kBrandDeep = AppColors.foundationRed800; // #B71130

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final bool isPhoneValid = state.phoneNumber.length > 9;
    final size = MediaQuery.of(context).size;
    final error = (state.errorMessage?.isEmpty ?? true)
        ? null
        : state.errorMessage;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Subtle brand aura in the bottom-right corner.
          Positioned(
            bottom: -size.width * 0.4,
            right: -size.width * 0.4,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                color: _kBrand.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Brand wordmark, top-left.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  'MassDriver',
                  style: AppTypography.heading4.copyWith(
                    color: _kBrand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'กรอกเบอร์โทรศัพท์ที่เคยสมัครไว้',
                    style: AppTypography.heading3.copyWith(color: _kTextPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'โปรดเพิ่มหมายเลขโทรศัพท์ของคุณ',
                    style: AppTypography.body1.copyWith(
                      color: _kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Phone input
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'เบอร์โทรศัพท์',
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextField(
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    buildCounter:
                        (_, {required currentLength, maxLength, required isFocused}) =>
                            null,
                    onChanged: controller.updatePhone,
                    style: AppTypography.body1.copyWith(color: _kTextPrimary),
                    decoration: InputDecoration(
                      hintText: '08X-XXX-XXXX',
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
                  ),

                  const SizedBox(height: 32),

                  // Continue button (gradient when enabled).
                  _ContinueButton(
                    label: 'รับรหัสยืนยัน',
                    enabled: isPhoneValid && !state.isLoading,
                    loading: state.isLoading,
                    onTap: () async {
                      final success = await controller.loginWithPhone();
                      if (success && context.mounted) {
                        // Read fresh state AFTER loginWithPhone() updates
                        // refId/isRegistered.
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
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.semanticErrorFgHigh,
                        ),
                      ),
                    ),

                  const SizedBox(height: 84),

                  // Version footer.
                  Center(
                    child: Text(
                      ref.watch(appVersionProvider).maybeWhen(
                            data: (v) => 'เวอร์ชัน $v',
                            orElse: () => '',
                          ),
                      textAlign: TextAlign.center,
                      style: AppTypography.body3.copyWith(
                        color: _kTextSecondary.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

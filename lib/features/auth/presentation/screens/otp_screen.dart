import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/features/account_restricted/presentation/widgets/account_restricted_dialog.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/auth/presentation/controllers/login_controller.dart';
import 'package:massdrive/features/auth/presentation/controllers/otp_controller.dart';
import 'package:massdrive/features/auth/presentation/widgets/auth_style.dart';
import 'package:pinput/pinput.dart';

/// How long the driver waits before a new OTP can be requested.
const otpResendCooldown = Duration(seconds: 60);

/// `02:59` for the resend countdown.
String formatCountdown(Duration d) {
  final s = d.inSeconds.clamp(0, 5999);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';
}

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String refId;
  final bool isRegistered;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.refId = '',
    this.isRegistered = true,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pin = TextEditingController();
  Timer? _timer;
  Duration _left = otpResendCooldown;
  bool _resending = false;

  /// Replaced by each resend: verification must use the latest request's ref.
  late String _refId = widget.refId;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pin.dispose();
    super.dispose();
  }

  void _startCooldown([Duration wait = otpResendCooldown]) {
    _timer?.cancel();
    _left = wait;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = _left - const Duration(seconds: 1);
      setState(() => _left = next.isNegative ? Duration.zero : next);
      if (_left == Duration.zero) t.cancel();
    });
  }

  /// Requests a fresh OTP through the same /otp/send call the login screen
  /// uses, then restarts the countdown with the new ref.
  Future<void> _resend() async {
    setState(() => _resending = true);
    final login = ref.read(loginControllerProvider.notifier);
    login.updatePhone(widget.phoneNumber);
    final ok = await login.loginWithPhone();
    if (!mounted) return;
    setState(() => _resending = false);
    final messenger = ScaffoldMessenger.of(context);
    if (!ok) {
      final login = ref.read(loginControllerProvider);
      final err = login.errorMessage;
      // Rate-limited (429 OTP_RATE_LIMITED): lock resend for retry_after.
      final wait = login.retryAfter;
      if (wait != null) setState(() => _startCooldown(wait));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            (err == null || err.isEmpty)
                ? 'ส่งรหัส OTP ไม่สำเร็จ ลองใหม่อีกครั้ง'
                : err,
          ),
        ),
      );
      return;
    }
    final fresh = ref.read(loginControllerProvider).refId;
    if (fresh.isNotEmpty) _refId = fresh;
    _pin.clear();
    ref.read(otpControllerProvider.notifier).updateOtp('');
    setState(_startCooldown);
    messenger.showSnackBar(
      const SnackBar(content: Text('ส่งรหัส OTP ใหม่แล้ว')),
    );
  }

  /// Masks the middle of the phone number, keeping the prefix and last three
  /// digits so the user can still recognise it. Display-only.
  String get _maskedPhone {
    final p = widget.phoneNumber;
    if (p.length <= 6) return p;
    final head = p.substring(0, 3);
    final tail = p.substring(p.length - 3);
    return '$head${'•' * (p.length - 6)}$tail';
  }

  /// Last four characters of the reference id. Refs are full UUIDs on some
  /// backends and overflow the subtitle; the tail is enough for a user to read
  /// back over the phone. Verification always sends the complete [refId].
  String get _shortRef =>
      _refId.length > 4 ? _refId.substring(_refId.length - 4) : _refId;

  @override
  Widget build(BuildContext context) {
    // Sign-in refused because the account is suspended: explain + offer a call.
    ref.listen(otpControllerProvider, (prev, next) {
      if (next.errorMessage == accountRestrictedLoginMessage &&
          prev?.errorMessage != accountRestrictedLoginMessage) {
        showAccountRestrictedDialog(context);
      }
      // Expired / replaced / too many wrong tries: this code is dead, so
      // unlock "รับรหัส OTP ใหม่" now instead of making the driver wait.
      if (next.needsNewCode && !(prev?.needsNewCode ?? false)) {
        _timer?.cancel();
        _pin.clear();
        setState(() => _left = Duration.zero);
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
                          'รหัส 6 หลักส่งไปที่ $_maskedPhone${_refId.isNotEmpty ? ' (Ref: $_shortRef)' : ''}',
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
                                controller: _pin,
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
                                    widget.phoneNumber,
                                    isRegistered: widget.isRegistered,
                                    refId: _refId,
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
                            const SizedBox(height: 24),
                            _ResendRow(
                              left: _left,
                              sending: _resending,
                              onResend: _resend,
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  'แก้ไขเบอร์โทรศัพท์',
                                  style: AppTypography.caption4.copyWith(
                                    color: AuthColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Bottom Button
                            AuthPrimaryButton(
                              label: 'ยืนยัน',
                              enabled: isOtpValid && !state.isLoading,
                              loading: state.isLoading,
                              onTap: () async {
                                final result = await controller.verifyOtp(
                                  widget.phoneNumber,
                                  isRegistered: widget.isRegistered,
                                  refId: _refId,
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

/// "ยังไม่ได้รับรหัส?" with a countdown, then a "รับรหัส OTP ใหม่" link once
/// [otpResendCooldown] has passed.
class _ResendRow extends StatelessWidget {
  final Duration left;
  final bool sending;
  final VoidCallback onResend;

  const _ResendRow({
    required this.left,
    required this.sending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.caption4.copyWith(
      color: AuthColors.textSecondary,
    );
    if (left > Duration.zero) {
      return Text.rich(
        TextSpan(
          text: 'ยังไม่ได้รับรหัส? ขอรหัสใหม่ได้ใน ',
          children: [
            TextSpan(
              text: formatCountdown(left),
              style: muted.copyWith(
                color: AuthColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: muted,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('ยังไม่ได้รับรหัส? ', style: muted),
        sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AuthColors.accent,
                ),
              )
            : InkWell(
                onTap: onResend,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    'รับรหัส OTP ใหม่',
                    style: muted.copyWith(
                      color: AuthColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

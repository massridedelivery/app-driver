import 'package:massdrive/features/auth/presentation/states/otp_state.dart';
import 'package:massdrive/features/auth/domain/usecase/verify_otp_usecase.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'otp_controller.g.dart';

enum OtpVerifyResult { home, registrationChecklist, error }

@riverpod
class OtpController extends _$OtpController {
  @override
  OtpState build() => const OtpState();

  void updateOtp(String code) {
    state = state.copyWith(otpCode: code, errorMessage: '');
  }

  /// [isRegistered] — value from /auth/otp/send response.
  /// After a successful verify:
  ///   - isRegistered == true  → navigate to Home
  ///   - isRegistered == false → navigate to Registration Checklist
  Future<OtpVerifyResult> verifyOtp(
    String phone, {
    bool isRegistered = true,
    String refId = '',
  }) async {
    if (state.otpCode.length < 6) {
      state = state.copyWith(errorMessage: 'Please enter 6-digit OTP');
      return OtpVerifyResult.error;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final verifyOtpUseCase = getIt<VerifyOtpUseCase>();
      await verifyOtpUseCase.execute(phone, state.otpCode, refId: refId);
      state = state.copyWith(isLoading: false);
      // Refresh auth state so the router knows the user is now logged in
      ref.read(authControllerProvider.notifier).refresh();
      return isRegistered ? OtpVerifyResult.home : OtpVerifyResult.registrationChecklist;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return OtpVerifyResult.error;
    }
  }
}

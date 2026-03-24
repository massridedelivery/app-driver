import 'package:massdrive/features/auth/presentation/states/otp_state.dart';
import 'package:massdrive/features/auth/domain/usecase/verify_otp_usecase.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'otp_controller.g.dart';

@riverpod
class OtpController extends _$OtpController {
  @override
  OtpState build() => const OtpState();

  void updateOtp(String code) {
    state = state.copyWith(otpCode: code, errorMessage: '');
  }

  Future<bool> verifyOtp(String phone) async {
    if (state.otpCode.length < 6) {
      state = state.copyWith(errorMessage: 'Please enter 6-digit OTP');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final verifyOtpUseCase = getIt<VerifyOtpUseCase>();
      await verifyOtpUseCase.execute(phone, state.otpCode);
      state = state.copyWith(isLoading: false);
      // Trigger Auth update so main app router knows user is logged in
      ref.read(authControllerProvider.notifier).refresh();
      return true; // Navigate to Home
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

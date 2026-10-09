import 'package:massdrive/features/auth/presentation/states/otp_state.dart';
import 'package:massdrive/features/auth/domain/usecase/verify_otp_usecase.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
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

  /// [isRegistered] — value from /auth/otp/send response, used only as a fallback
  /// hint. The real destination is derived from the driver's actual profile after
  /// verify (see below), because the backend returns is_registered=true whenever
  /// an account exists for the phone — even a customer-only or half-registered
  /// driver — which used to send such drivers straight to Home and skip the whole
  /// name/registration flow, leaving them with no name (admin then shows the phone).
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
      // Refresh auth state and WAIT for it to settle before navigating. This
      // re-derives the session from the freshly stored token and pushes the
      // result into SessionNotifier (the router's refreshListenable). If we
      // navigate first and let this run un-awaited, a late session flip can
      // redirect the just-opened protected screen straight back to /login.
      await ref.read(authControllerProvider.notifier).refresh();

      // Decide the destination from the driver's actual profile rather than
      // trusting is_registered alone. A verified driver goes Home; one who has
      // no real name yet still needs to register, regardless of is_registered.
      // Falls back to the is_registered hint if the profile can't be read.
      try {
        await ref.read(profileControllerProvider.notifier).fetchProfile();
        final profile = ref.read(profileControllerProvider).profile;
        if (profile != null) {
          if (profile.isVerified) return OtpVerifyResult.home;
          final name = profile.fullName.trim();
          final hasRealName = name.isNotEmpty && name != 'New Driver';
          if (!hasRealName) return OtpVerifyResult.registrationChecklist;
        }
      } catch (_) {
        // Profile fetch failed — fall through to the is_registered hint.
      }

      return isRegistered ? OtpVerifyResult.home : OtpVerifyResult.registrationChecklist;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return OtpVerifyResult.error;
    }
  }
}

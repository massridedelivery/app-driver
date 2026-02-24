import 'package:flutter/foundation.dart';
import 'package:massdrive/features/auth/domain/usecase/login_with_phone_usecase.dart';
import 'package:massdrive/features/auth/presentation/states/login_state.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState();

  void updatePhone(String phone) {
    state = state.copyWith(phoneNumber: phone, errorMessage: '');
  }

  Future<bool> loginWithPhone() async {
    debugPrint(
      'LoginController.loginWithPhone called with: ${state.phoneNumber}',
    );
    if (state.phoneNumber.isEmpty || state.phoneNumber.length < 9) {
      debugPrint('LoginController: Phone number invalid');
      state = state.copyWith(errorMessage: 'Please enter a valid phone number');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      debugPrint('LoginController: Calling use case...');
      final loginUseCase = getIt<LoginWithPhoneUseCase>();
      await loginUseCase.execute(state.phoneNumber);
      debugPrint('LoginController: Use case success');
      state = state.copyWith(isLoading: false);
      return true; // Navigate to OTP
    } catch (e) {
      debugPrint('LoginController: Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:massdrive/features/auth/domain/usecase/login_with_email_usecase.dart';
import 'package:massdrive/features/auth/presentation/states/email_login_state.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'email_login_controller.g.dart';

@riverpod
class EmailLoginController extends _$EmailLoginController {
  @override
  EmailLoginState build() => const EmailLoginState();

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: '');
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: '');
  }

  Future<bool> loginWithEmail() async {
    debugPrint('EmailLoginController.loginWithEmail called: ${state.email}');
    if (state.email.isEmpty || !state.email.contains('@')) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email address',
      );
      return false;
    }
    if (state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a password');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final loginUseCase = getIt<LoginWithEmailUseCase>();
      await loginUseCase.execute(state.email, state.password);

      // Refresh AuthController to update global auth state (like Phone Login does)
      ref.read(authControllerProvider.notifier).refresh();

      state = state.copyWith(isLoading: false);
      return true; // Navigate to Home
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

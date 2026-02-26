import 'package:flutter/foundation.dart';
import 'package:massdrive/features/auth/domain/entities/register_request.dart';
import 'package:massdrive/features/auth/domain/usecase/register_usecase.dart';
import 'package:massdrive/features/auth/presentation/states/register_state.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  RegisterState build() => const RegisterState();

  void updateFields({
    String? fullName,
    String? email,
    String? phone,
    String? password,
  }) {
    state = state.copyWith(
      fullName: fullName ?? state.fullName,
      email: email ?? state.email,
      phone: phone ?? state.phone,
      password: password ?? state.password,
      errorMessage: '',
    );
  }

  Future<bool> register() async {
    debugPrint('RegisterController.register called');

    if (state.fullName.isEmpty ||
        state.email.isEmpty ||
        state.phone.isEmpty ||
        state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Please fill all fields');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final registerUseCase = getIt<RegisterUseCase>();
      
      final request = RegisterRequest(
        email: state.email,
        fullName: state.fullName,
        password: state.password,
        phone: state.phone,
        role: 'driver',
      );

      await registerUseCase.execute(request);
      
      state = state.copyWith(isLoading: false);
      return true; // Navigate to Home
    } catch (e) {
      debugPrint('RegisterController: Error \$e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

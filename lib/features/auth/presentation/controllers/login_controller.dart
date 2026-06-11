import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
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

      // Get device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      if (kIsWeb) {
        deviceId = 'web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      final otpResponse = await loginUseCase.execute(state.phoneNumber, deviceId);
      debugPrint('LoginController: Use case success: refId=${otpResponse.refId}, isRegistered=${otpResponse.isRegistered}');
      
      state = state.copyWith(
        isLoading: false,
        refId: otpResponse.refId,
        isRegistered: otpResponse.isRegistered,
      );
      return true; // Navigate to OTP
    } catch (e) {
      debugPrint('LoginController: Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}


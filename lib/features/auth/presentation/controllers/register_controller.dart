import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/features/auth/domain/entities/register_request.dart';
import 'package:massdrive/features/auth/domain/usecase/register_usecase.dart';
import 'package:massdrive/features/auth/presentation/states/register_state.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

      // Collect device & app info
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = '';
      String deviceModel = '';
      String os = '';
      String osVersion = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        os = 'android';
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        deviceModel = iosInfo.model;
        os = 'ios';
        osVersion = iosInfo.systemVersion;
      }

      final request = RegisterRequest(
        email: state.email,
        fullName: state.fullName,
        password: state.password,
        phone: state.phone,
        role: 'driver',
        appVersion: packageInfo.version,
        deviceId: deviceId,
        deviceModel: deviceModel,
        integrityToken: '',
        os: os,
        osVersion: osVersion,
      );

      await registerUseCase.execute(request);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('RegisterController: Error $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

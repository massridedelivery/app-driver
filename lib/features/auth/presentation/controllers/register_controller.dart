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

/// Outcome of a registration attempt. [alreadyExists] (HTTP 409) means a driver
/// account for this phone/email already exists → the UI sends them to login.
enum RegisterResult { success, error, alreadyExists }

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

  Future<RegisterResult> register() async {
    debugPrint('RegisterController.register called');

    if (state.fullName.isEmpty ||
        state.email.isEmpty ||
        state.phone.isEmpty ||
        state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Please fill all fields');
      return RegisterResult.error;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final registerUseCase = getIt<RegisterUseCase>();

      // Collect device & app info
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = '';
      String deviceModel = '';
      String os = '';
      String osVersion = '';

      // Isolated in its own try/catch: some emulator/device images return a
      // null field the plugin doesn't guard against internally, throwing a
      // raw TypeError that would otherwise abort the whole registration.
      // These fields are informational only, so empty fallbacks are safe.
      try {
        final deviceInfo = DeviceInfoPlugin();
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
      } catch (e) {
        debugPrint('RegisterController: device info unavailable: $e');
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
      return RegisterResult.success;
    } catch (e) {
      debugPrint('RegisterController: Error $e');
      final msg = e.toString();
      // 409: a driver account for this phone/email already exists → go to login.
      if (msg.contains('ACCOUNT_EXISTS') ||
          msg.toLowerCase().contains('already registered')) {
        state = state.copyWith(isLoading: false);
        return RegisterResult.alreadyExists;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return RegisterResult.error;
    }
  }
}

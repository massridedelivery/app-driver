import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/auth/domain/entities/user_entity.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';
import 'package:massdrive/features/auth/domain/usecase/verify_otp_usecase.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/auth/presentation/controllers/otp_controller.dart';
import 'package:massdrive/features/auth/presentation/states/auth_state.dart';
import 'package:massdrive/features/dependency_injection.dart';

class _NoRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Verify that answers only when the test says so.
class _SlowVerify extends VerifyOtpUseCase {
  _SlowVerify() : super(_NoRepo());
  final done = Completer<void>();
  Object? failWith;

  @override
  Future<UserEntity> execute(
    String phone,
    String otp, {
    String refId = '',
  }) async {
    await done.future;
    if (failWith != null) throw failWith!;
    return UserEntity(id: 'd1', name: 'ทดสอบ', phoneNumber: phone, token: 't');
  }
}

class _Auth extends AuthController {
  static int refreshes = 0;
  @override
  Future<AuthState> build() async => const AuthState(false);
  @override
  Future<void> refresh() async => refreshes++;
}

void main() {
  late _SlowVerify verify;

  setUp(() {
    verify = _SlowVerify();
    getIt.registerSingleton<VerifyOtpUseCase>(verify);
    _Auth.refreshes = 0;
  });
  tearDown(() => getIt.reset());

  ProviderContainer make() => ProviderContainer(
    overrides: [authControllerProvider.overrideWith(_Auth.new)],
  );

  // A successful verify stores the token, the router leaves the OTP screen and
  // the autoDispose controller is gone before the call returns. It used to
  // throw "Cannot use the Ref of otpControllerProvider after it has been
  // disposed" (Crashlytics, Android 1.0.1).
  test('a verify that outlives the OTP screen still signs in', () async {
    final c = make();
    addTearDown(c.dispose);
    final authSub = c.listen(authControllerProvider, (_, _) {});
    addTearDown(authSub.close);
    final sub = c.listen(otpControllerProvider, (_, _) {});
    final otp = c.read(otpControllerProvider.notifier)..updateOtp('123456');

    final result = otp.verifyOtp('0653333333');
    sub.close(); // the screen went away
    await pumpEventQueue();
    verify.done.complete();

    expect(await result, OtpVerifyResult.home);
    expect(_Auth.refreshes, 1);
  });

  test('a failed verify after the screen closed is quiet', () async {
    final c = make();
    addTearDown(c.dispose);
    final sub = c.listen(otpControllerProvider, (_, _) {});
    final otp = c.read(otpControllerProvider.notifier)..updateOtp('123456');

    final result = otp.verifyOtp('0653333333');
    sub.close();
    await pumpEventQueue();
    verify
      ..failWith = Exception('network')
      ..done.complete();

    expect(await result, OtpVerifyResult.error);
  });
}

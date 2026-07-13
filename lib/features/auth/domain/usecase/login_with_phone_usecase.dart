import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/domain/entities/otp_response.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class LoginWithPhoneUseCase {
  final AuthRepository _repository;

  LoginWithPhoneUseCase(this._repository);

  Future<OtpResponse> execute(String phone, String deviceId) async {
    return _repository.loginWithPhone(phone: phone, deviceId: deviceId);
  }
}


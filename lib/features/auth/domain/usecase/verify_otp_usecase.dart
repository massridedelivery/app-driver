import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/domain/entities/user_entity.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class VerifyOtpUseCase {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  Future<UserEntity> execute(String phone, String otp, {String refId = ''}) async {
    return _repository.verifyOtp(phone, otp, refId: refId);
  }
}

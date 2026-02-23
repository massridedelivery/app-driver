import 'package:massdrive/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> loginWithPhone(String phone);
  Future<UserEntity> verifyOtp(String phone, String otp);
}

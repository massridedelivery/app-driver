import 'package:massdrive/features/auth/domain/entities/user_entity.dart';
import 'package:massdrive/features/auth/domain/entities/register_request.dart';
import 'package:massdrive/features/auth/domain/entities/otp_response.dart';

abstract class AuthRepository {
  Future<OtpResponse> loginWithPhone({required String phone, required String deviceId});
  Future<UserEntity> verifyOtp(String phone, String otp, {String refId = ''});
  Future<UserEntity> loginWithEmail(String email, String password);
  Future<UserEntity> register(RegisterRequest request);
  Future<void> logout();
}


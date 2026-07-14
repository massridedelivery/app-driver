import 'package:massdrive/features/auth/data/models/register_request_model.dart';
import 'package:massdrive/features/auth/data/models/otp_response_model.dart';

abstract class AuthApiService {
  Future<OtpResponseModel> requestOtp({required String phone, required String deviceId});
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String refId = ''});
  Future<Map<String, dynamic>> loginWithEmail(String email, String password);
  Future<Map<String, dynamic>> register(RegisterRequestModel request);
}


abstract class AuthApiService {
  Future<void> requestOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp);
}

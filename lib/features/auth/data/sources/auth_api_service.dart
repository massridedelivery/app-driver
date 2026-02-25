abstract class AuthApiService {
  Future<void> requestOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp);
  Future<Map<String, dynamic>> loginWithEmail(String email, String password);
}

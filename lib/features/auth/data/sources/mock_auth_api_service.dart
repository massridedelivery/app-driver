import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/data/sources/auth_api_service.dart';

@LazySingleton(as: AuthApiService)
class MockAuthApiService implements AuthApiService {
  @override
  Future<void> requestOtp(String phone) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would trigger an SMS gateway. 
    // For our mock, we just pretend it succeeded.
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Check for a dummy OTP or accept any for testing
    if (otp == '123456') {
      return {
        'id': 'drv_123456',
        'name': 'Somchai Driver',
        'phoneNumber': phone,
        'token': 'mock_jwt_token_abcdef123456',
      };
    } else {
      throw Exception('Invalid OTP format. Try 123456');
    }
  }
}

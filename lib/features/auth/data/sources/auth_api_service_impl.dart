import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/auth/data/models/register_request_model.dart';
import 'package:massdrive/features/auth/data/sources/auth_api_service.dart';

@LazySingleton(as: AuthApiService)
class AuthApiServiceImpl implements AuthApiService {
  final Dio _dio;

  AuthApiServiceImpl(this._dio);

  @override
  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post(
        Endpoints.otpPhoneRequest,
        data: {'phone': phone, 'role': 'driver'},
      );
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to request OTP');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final verifyResponse = await _dio.post(
        Endpoints.phoneVerify,
        data: {
          'phone': phone,
          'code': otp,
          'role': 'driver',
          'full_name': 'New Driver', // Used if first time login
        },
      );

      final accessToken = verifyResponse.data['access_token'];

      // Fetch profile using the token
      return await _fetchDriverProfile(accessToken, phone);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to verify OTP');
    }
  }

  @override
  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final loginResponse = await _dio.post(
        Endpoints.login,
        data: {'email': email, 'password': password},
      );

      final accessToken = loginResponse.data['access_token'];

      // Temporarily removed _fetchDriverProfile per user request
      return {
        'id': 'drv_123',
        'name': 'Driver (Email)',
        'phoneNumber': '', // No phone from email login yet
        'token': accessToken,
      };
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to login with email');
    }
  }

  @override
  Future<Map<String, dynamic>> register(RegisterRequestModel request) async {
    try {
      final response = await _dio.post(
        Endpoints.register,
        data: request.toJson(),
      );

      final accessToken = response.data['access_token'];

      // Temporarily return user data structuring until backend provides profile from registration or another endpoint is hit
      return {
        'id': 'drv_new_123',
        'name': request.fullName,
        'phoneNumber': request.phone,
        'token': accessToken,
      };
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to register');
    }
  }

  Future<Map<String, dynamic>> _fetchDriverProfile(
    String accessToken,
    String fallbackPhone,
  ) async {
    try {
      // Pass token explicitly since it might not be saved to storage yet
      final profileResponse = await _dio.get(
        Endpoints.driverProfile,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final profile = profileResponse.data;

      return {
        'id': profile['user_id'] ?? '',
        'name': profile['full_name'] ?? 'Driver',
        'phoneNumber': profile['phone'] ?? fallbackPhone,
        'token': accessToken,
      };
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to fetch driver profile');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/auth/data/models/register_request_model.dart';
import 'package:massdrive/features/auth/data/models/otp_response_model.dart';
import 'package:massdrive/features/auth/data/sources/auth_api_service.dart';

@LazySingleton(as: AuthApiService)
class AuthApiServiceImpl implements AuthApiService {
  final Dio _dio;

  AuthApiServiceImpl(this._dio);

  @override
  Future<OtpResponseModel> requestOtp({
    required String phone,
    required String deviceId,
  }) async {
    try {
      // Normalize phone to E.164 format: replace leading 0 with +66
      final normalizedPhone = phone.startsWith('0')
          ? '+66${phone.substring(1)}'
          : phone;

      final response = await _dio.post(
        Endpoints.otpPhoneRequest,
        data: {'phone': normalizedPhone, 'device_id': deviceId},
        options: Options(
          extra: {
            'feature': 'Auth',
            'endPoint': Endpoints.otpPhoneRequest,
          },
        ),
      );
      return OtpResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to request OTP');
    }
  }


  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String refId = ''}) async {
    try {
      // Normalize phone to E.164 format: replace leading 0 with +66
      final normalizedPhone = phone.startsWith('0')
          ? '+66${phone.substring(1)}'
          : phone;

      final verifyResponse = await _dio.post(
        Endpoints.phoneVerify,
        data: {
          'phone': normalizedPhone,
          'otp': otp,
          'ref_id': refId,
          'role': 'driver',
          'full_name': 'New Driver',
        },
        options: Options(extra: {'feature': 'Auth', 'endPoint': Endpoints.phoneVerify}),
      );

      final accessToken = verifyResponse.data['access_token'];

      // Fetch profile using the token
      return await _fetchDriverProfile(accessToken, normalizedPhone);
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
        options: Options(extra: {'feature': 'Auth', 'endPoint': Endpoints.login}),
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
        options: Options(extra: {'feature': 'Auth', 'endPoint': Endpoints.register}),
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

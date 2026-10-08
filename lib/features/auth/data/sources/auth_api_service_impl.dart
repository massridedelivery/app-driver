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
        data: {'phone': normalizedPhone, 'device_id': deviceId, 'role': 'driver'},
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
          // No placeholder name — the driver's real name is set later from the
          // registration profile form (PUT /api/driver/profile). Sending a
          // "New Driver" placeholder here made every new driver show up as
          // "New Driver" in admin/profile. full_name is optional on verify.
        },
        options: Options(extra: {'feature': 'Auth', 'endPoint': Endpoints.phoneVerify}),
      );

      final accessToken = verifyResponse.data['access_token'];
      final refreshToken = verifyResponse.data['refresh_token'];

      // Fetch profile using the token
      final profile = await _fetchDriverProfile(accessToken, normalizedPhone);
      profile['refresh_token'] = refreshToken;
      return profile;
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
        data: {'email': email, 'password': password, 'role': 'driver'},
        options: Options(extra: {'feature': 'Auth', 'endPoint': Endpoints.login}),
      );

      final accessToken = loginResponse.data['access_token'];
      final refreshToken = loginResponse.data['refresh_token'];

      // Fetch the real driver profile with the fresh token (same as the OTP
      // flow) instead of returning a placeholder.
      final profile = await _fetchDriverProfile(accessToken, '');
      profile['refresh_token'] = refreshToken;
      return profile;
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
      final refreshToken = response.data['refresh_token'];

      // Fetch the real driver profile with the fresh token. If it isn't
      // queryable yet right after registration, fall back to the submitted data
      // (no fake placeholder id) — the real profile loads on the next fetch.
      try {
        final profile = await _fetchDriverProfile(accessToken, request.phone);
        profile['refresh_token'] = refreshToken;
        return profile;
      } catch (_) {
        return {
          'id': '',
          'name': request.fullName,
          'phoneNumber': request.phone,
          'token': accessToken,
          'refresh_token': refreshToken,
        };
      }
    } on DioException catch (e) {
      // 409 = a driver account for this phone/email already exists → the UI
      // routes to login instead of showing a raw error. (BE multi-type identity.)
      if (e.response?.statusCode == 409) {
        throw Exception('ACCOUNT_EXISTS');
      }
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

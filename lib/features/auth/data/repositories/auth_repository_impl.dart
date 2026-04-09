import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/data/sources/auth_api_service.dart';
import 'package:massdrive/features/auth/domain/entities/user_entity.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/features/auth/data/models/user_model.dart';
import 'package:massdrive/features/auth/domain/entities/register_request.dart';
import 'package:massdrive/features/auth/data/models/register_request_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<void> loginWithPhone(String phone) async {
    await _apiService.requestOtp(phone);
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    final response = await _apiService.verifyOtp(phone, otp);
    final user = UserModel.fromJson(response);

    // Store token securely
    final secureStorage = SecureStorageManager();
    await secureStorage.write(SecureStorageKey.accessToken, user.token);

    return user;
  }

  @override
  Future<void> logout() async {
    final secureStorage = SecureStorageManager();
    await secureStorage.delete(SecureStorageKey.accessToken);
    
    // Clear Shared Preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Future<UserEntity> loginWithEmail(String email, String password) async {
    final response = await _apiService.loginWithEmail(email, password);
    final user = UserModel.fromJson(response);

    // Store token securely
    final secureStorage = SecureStorageManager();
    await secureStorage.write(SecureStorageKey.accessToken, user.token);

    return user;
  }

  @override
  Future<UserEntity> register(RegisterRequest request) async {
    final response = await _apiService.register(
      RegisterRequestModel.fromEntity(request),
    );
    final user = UserModel.fromJson(response);

    // Store token securely
    final secureStorage = SecureStorageManager();
    await secureStorage.write(SecureStorageKey.accessToken, user.token);

    return user;
  }
}

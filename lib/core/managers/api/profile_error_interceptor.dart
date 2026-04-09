import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileErrorInterceptor extends Interceptor {
  final SecureStorageManager _secureStorage = SecureStorageManager();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    // Specific logic for /api/driver/profile
    if (path.contains(Endpoints.driverProfile)) {
      if (statusCode == 400 || statusCode == 401) {
        // 1. Clear Shared Preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 2. Clear Secure Storage (tokens, etc.)
        await _secureStorage.deleteAll();

        // 3. Navigate to Login Flow
        AppRouter.router.go(AppRoutes.loginNamedPage);
        
        // Return to prevent further error handling for this specific case if needed
        // but we usually want to let the error bubble up or resolve it.
        // Since we are redirecting, the current context will be destroyed anyway.
      }
    }

    super.onError(err, handler);
  }
}

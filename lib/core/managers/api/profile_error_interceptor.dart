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

    // Only a genuine 401 on the profile endpoint means the session is dead and
    // the driver must sign in again. A 400 here is NOT an auth failure — it's a
    // business state (profile incomplete / not yet approved) that a freshly
    // verified driver legitimately hits, and the home/registration flow already
    // handles it via `isVerified`. Logging out on 400 was bouncing drivers
    // straight back to the phone-entry screen right after a successful OTP.
    //
    // This 401 branch fires only after the refresh-token interceptor (earlier in
    // the chain) has already tried and failed to renew the token, so it is a
    // last resort, not a first response to a 401.
    if (path.contains(Endpoints.driverProfile) && statusCode == 401) {
      // Clear any stored session, then send the driver to the login flow.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _secureStorage.deleteAll();
      AppRouter.router.go(AppRoutes.loginNamedPage);
    }

    super.onError(err, handler);
  }
}

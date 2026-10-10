import 'package:dio/dio.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileErrorInterceptor extends Interceptor {
  final SecureStorageManager _secureStorage = SecureStorageManager();

  bool _isProfile(RequestOptions options) =>
      options.path.endsWith(Endpoints.driverProfile);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // A profile read can itself say the account is suspended/deleted.
    if (_isProfile(response.requestOptions)) {
      _flagRestriction(
        isProfile: true,
        statusCode: response.statusCode,
        data: response.data,
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    // Deleted (profile 404) or suspended (403) account: the token is still
    // valid, so this is not a logout — flag it and let the router show the
    // "contact the company" screen instead of a home that can't load.
    _flagRestriction(
      isProfile: _isProfile(err.requestOptions),
      statusCode: statusCode,
      data: err.response?.data,
    );

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

  void _flagRestriction({
    required bool isProfile,
    required int? statusCode,
    required Object? data,
  }) {
    final restriction = detectAccountRestriction(
      statusCode: statusCode,
      data: data,
      isProfileEndpoint: isProfile,
    );
    if (restriction != null) {
      AccountStatusNotifier.instance.markRestricted(restriction);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/auth/session_trail.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileErrorInterceptor extends Interceptor {
  ProfileErrorInterceptor({Future<String?> Function()? currentToken})
    : _currentToken = currentToken;

  final SecureStorageManager _secureStorage = SecureStorageManager();

  /// The stored access token (overridable in tests).
  final Future<String?> Function()? _currentToken;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    // Deleted / suspended account (403 + code, on any authenticated endpoint
    // including /auth/refresh): flag it and let the router show the "contact
    // the company" screen. Not a logout — the backend keeps the tokens usable
    // so a lifted suspension works straight away.
    final restriction = detectAccountRestriction(
      statusCode: statusCode,
      data: err.response?.data,
    );
    if (restriction != null && !await _sentWithOldToken(err.requestOptions)) {
      AccountStatusNotifier.instance.markRestricted(restriction);
    }

    // Only a genuine 401 on the profile endpoint means the session is dead and
    // the driver must sign in again. A 400 here is NOT an auth failure — it's a
    // business state (profile incomplete / not yet approved) that a freshly
    // verified driver legitimately hits, and the home/registration flow already
    // handles it via `isVerified`. Logging out on 400 was bouncing drivers
    // straight back to the phone-entry screen right after a successful OTP.
    //
    // This 401 branch fires only after the refresh-token interceptor (earlier in
    // the chain) has already tried and failed to renew the token, so it is a
    // last resort, not a first response to a 401. A restricted account keeps
    // its session (the refresh was refused with 403, not a dead token).
    if (path.contains(Endpoints.driverProfile) &&
        statusCode == 401 &&
        !AccountStatusNotifier.instance.isRestricted) {
      // Clear any stored session, then send the driver to the login flow.
      if (SessionNotifier.instance.isAuthenticated) {
        SessionTrail.ended('profile 401');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _secureStorage.deleteAll();
      SessionNotifier.instance.setAuthenticated(false);
      AppRouter.router.go(AppRoutes.loginNamedPage);
    }

    super.onError(err, handler);
  }

  /// True when the request carried a bearer token that is no longer the
  /// stored one — a late reply from the previous (e.g. deleted) account,
  /// which must not flag the account the driver just signed into.
  Future<bool> _sentWithOldToken(RequestOptions options) async {
    final sent = bearerToken(options.headers);
    if (sent == null) return false;
    try {
      final current =
          await (_currentToken?.call() ??
              _secureStorage.read(SecureStorageKey.accessToken));
      return current != null && current != sent;
    } catch (_) {
      return false;
    }
  }
}

/// The token from an `Authorization: Bearer …` header, or null.
String? bearerToken(Map<String, dynamic> headers) {
  final value = (headers['Authorization'] ?? headers['authorization'])
      ?.toString();
  if (value == null || !value.startsWith('Bearer ')) return null;
  final token = value.substring(7).trim();
  return token.isEmpty ? null : token;
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/services/route_restoration_service.dart';
import 'package:massdrive/features/auth/presentation/states/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/features/dependency_injection.dart' as massdrive_di;
import 'package:massdrive/features/auth/domain/usecase/logout_usecase.dart'
    as massdrive_logout;

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late final SecureStorageManager _secureStorage;

  Future<AuthState> get _state async {
    final loggedIn = await _hasValidSession();
    // Seed the router's session source of truth from the real (expiry-aware)
    // state so a redirect is in effect from the first frame.
    SessionNotifier.instance.setAuthenticated(loggedIn);
    return AuthState(loggedIn);
  }

  /// A session is valid when a non-expired access token exists — or the access
  /// token is expired but a refresh token is present for the interceptor to
  /// exchange. Merely having a stored (possibly expired/revoked) token is no
  /// longer treated as logged in; if a later refresh fails the API layer flips
  /// the session to logged-out via [SessionNotifier].
  Future<bool> _hasValidSession() async {
    // Keychain reads can fail outright — notably right after the app is
    // re-signed or updated (TestFlight), where iOS can return -34018. Letting
    // that throw propagates all the way to the splash screen, which has no
    // recovery path and simply sits there. No readable token means no usable
    // session, so answer "logged out" and let the driver sign in again.
    final String? token;
    try {
      token = await _secureStorage.read(SecureStorageKey.accessToken);
    } catch (e) {
      debugPrint('AuthController: access token read failed: $e');
      return false;
    }
    if (token == null || token.isEmpty) return false;

    bool expired;
    try {
      expired = JwtDecoder.isExpired(token);
    } catch (_) {
      // The access token isn't a decodable JWT (e.g. an opaque token the
      // backend issues). We can't read an expiry from it, so we must not judge
      // the session dead on that basis — doing so logged the driver straight
      // back out the moment after a successful OTP/email login (the stored
      // token bypasses this check during the login request, then fails it on
      // the post-login re-check). Treat the mere presence of a token as a live
      // session; if it's actually dead, the API layer flips the session to
      // logged-out on the first 401 via [SessionNotifier].
      return true;
    }
    if (!expired) return true;

    try {
      final refresh = await _secureStorage.read(SecureStorageKey.refreshToken);
      return refresh != null && refresh.isNotEmpty;
    } catch (e) {
      debugPrint('AuthController: refresh token read failed: $e');
      return false;
    }
  }

  bool get isLogin {
    return state.value?.isLogin ?? false;
  }

  @override
  Future<AuthState> build() async {
    _secureStorage = SecureStorageManager();
    return await _state;
  }

  Future<void> refresh() async {
    // This controller is autoDispose and often has no listener when refresh()
    // is triggered (e.g. right after OTP verify, where the OTP screen watches
    // its own controller, not this one). Riverpod can dispose it during the
    // await below; the routing-critical work — SessionNotifier being updated
    // inside [_state] — has already happened by then, so only guard the state
    // assignment. Writing to a disposed notifier throws ("Cannot use the Ref
    // ... after it has been disposed"), which previously surfaced as an error
    // on the OTP screen.
    final next = await _state;
    if (!ref.mounted) return;
    state = AsyncValue.data(next);
  }

  /// Ends the session and drives the app back to login. The session teardown
  /// runs in a `finally` so a failing network logout (expired token, offline)
  /// can never strand the driver on a protected screen: local tokens are
  /// wiped and the router redirect fires regardless. Works the same for phone
  /// and email sessions, since both funnel through [SessionNotifier].
  Future<void> logout() async {
    try {
      final usecase = massdrive_di.getIt<massdrive_logout.LogoutUseCase>();
      await usecase.execute();
    } catch (e) {
      debugPrint('AuthController: logout call failed, forcing local logout: $e');
    } finally {
      await RouteRestorationService.instance.clear();
      SessionNotifier.instance.setAuthenticated(false);
      await refresh();
    }
  }

  /// Permanently deletes the driver's account server-side (SCRUM-61,
  /// DELETE /api/driver/account with an optional `{reason}`), then tears down
  /// the local session so the app returns to login.
  ///
  /// A delete failure is rethrown BEFORE any local logout — the account still
  /// exists, so the caller must surface the error rather than silently signing
  /// the driver out.
  Future<void> deleteAccount({String? reason}) async {
    final dio = massdrive_di.getIt<Dio>();
    await dio.delete(
      Endpoints.driverAccount,
      data: (reason != null && reason.trim().isNotEmpty)
          ? {'reason': reason.trim()}
          : null,
    );
    // Server-side deletion succeeded — clear the local session too.
    await logout();
  }
}

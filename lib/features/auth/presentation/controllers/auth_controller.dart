import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
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
      // Unparseable token -> treat as a dead session rather than trust it.
      return false;
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
    state = AsyncValue.data(await _state);
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
}

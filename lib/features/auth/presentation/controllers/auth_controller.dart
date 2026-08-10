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
    final token = await _secureStorage.read(SecureStorageKey.accessToken);
    if (token == null || token.isEmpty) return false;

    bool expired;
    try {
      expired = JwtDecoder.isExpired(token);
    } catch (_) {
      // Unparseable token -> treat as a dead session rather than trust it.
      return false;
    }
    if (!expired) return true;

    final refresh = await _secureStorage.read(SecureStorageKey.refreshToken);
    return refresh != null && refresh.isNotEmpty;
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

  Future<void> logout() async {
    final usecase = massdrive_di.getIt<massdrive_logout.LogoutUseCase>();
    await usecase.execute();
    await RouteRestorationService.instance.clear();
    SessionNotifier.instance.setAuthenticated(false);
    await refresh();
  }
}

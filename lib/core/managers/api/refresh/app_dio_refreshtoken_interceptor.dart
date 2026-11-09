import 'dart:async';

import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/auth/session_trail.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/features/auth/data/models/auth_token_model.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';

class AppDioRefreshTokenInterceptor extends Interceptor {
  AppDioRefreshTokenInterceptor({
    required this.secureStorage,
    required this.dio,
    this.authController,
    this.onTokenExpired,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 6),
    ],
  });

  final SecureStorageManager secureStorage;
  final Dio dio;
  final AuthController? authController;
  final FutureOr<void> Function()? onTokenExpired;

  /// Waits between refresh attempts that got no verdict (no reply, a
  /// timeout, a 5xx). Every attempt sends the SAME refresh token: within 60 s
  /// of a rotation the server answers it with the pair it already issued, so
  /// a reply lost to a network drop or an app suspend no longer costs the
  /// session. Kept well inside that grace window.
  final List<Duration> retryDelays;

  static Completer<void>? _refreshCompleter;

  /// Why the last refresh failed, for [SessionTrail].
  String _refreshFailure = 'refresh failed';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isRefreshTokenRequest(options)) {
      return handler.next(options);
    }

    // A caller that set Authorization itself knows something storage doesn't
    // yet. Sign-in is the case that matters: verifyOtp fetches the driver
    // profile with the token the verify call just returned, before it has been
    // persisted. Overwriting that with the stale token still in storage made
    // the profile call 401, which drove a refresh with the previous refresh
    // token — already revoked by the sign-in — so the app wiped the session and
    // bounced the driver back to the phone screen moments after a successful
    // OTP.
    if (options.headers.containsKey('Authorization')) {
      return handler.next(options);
    }

    final accessToken = await secureStorage.read(SecureStorageKey.accessToken);
    if (accessToken == null) {
      return handler.next(options);
    }

    bool isTokenExpired;
    try {
      isTokenExpired = JwtDecoder.isExpired(accessToken);
    } catch (_) {
      // Opaque (non-JWT) access token — there's no readable `exp` to check.
      // Don't throw here (that would fail every authenticated request) and
      // don't force a refresh on every call; attach the token as-is and let a
      // real 401 drive the refresh/logout path in onError.
      isTokenExpired = false;
    }

    if (isTokenExpired) {
      try {
        final newAccessToken = await _lockAndRefreshToken();
        if (newAccessToken != null) {
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          return handler.next(options);
        } else {
          options.headers.remove('Authorization');
          return handler.next(options);
        }
      } catch (e) {
        options.headers.remove('Authorization');
        return handler.next(options);
      }
    } else {
      options.headers['Authorization'] = 'Bearer $accessToken';
      return handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isUnauthorized(err) ||
        _isRefreshTokenRequest(err.requestOptions) ||
        _isOtpRequest(err.requestOptions)) {
      return handler.next(err);
    }

    try {
      final newAccessToken = await _lockAndRefreshToken();
      if (newAccessToken != null) {
        final response = await _retryRequest(
          err.requestOptions,
          newAccessToken,
        );
        return handler.resolve(response);
      } else {
        return handler.next(err);
      }
    } catch (_) {
      return handler.next(err);
    }
  }

  /// For a 401 that reached the caller instead of [onError] — [ApiManager]
  /// writes accept every status, so their 401s skip this interceptor. Renews
  /// the session if it can; [sentToken] is the access token the request
  /// carried. Before, such a 401 signed the driver out on the spot, without a
  /// refresh: a phone clock running behind (the token looks valid here, the
  /// server says expired) was enough.
  Future<TokenRenewal> renewAfter401(String sentToken) async {
    final stored = await secureStorage.read(SecureStorageKey.accessToken);
    if (stored == null || stored.isEmpty) return const TokenRenewal.ended();
    // Another request already renewed it while this one was in flight.
    if (stored != sentToken) return TokenRenewal.renewed(stored);

    final fresh = await _lockAndRefreshToken();
    if (fresh != null && fresh != sentToken) return TokenRenewal.renewed(fresh);
    final left = await secureStorage.read(SecureStorageKey.accessToken);
    // Tokens still stored: the refresh couldn't reach the server, or the
    // account is restricted — not a dead session.
    return left == null
        ? const TokenRenewal.ended()
        : const TokenRenewal.kept();
  }

  // MARK: - QA (the hidden "ทดสอบ session" sheet in Settings)

  /// A refresh now, the way a 401 would start one (through the lock).
  Future<TokenRenewal> qaRefreshNow() async {
    SessionTrail.step('qa: refresh now');
    final sent = await secureStorage.read(SecureStorageKey.accessToken);
    return renewAfter401(sent ?? '');
  }

  /// Sends a refresh and throws the reply away — a reply lost to a network
  /// drop or an app kill. Storage keeps the token the server just rotated,
  /// so the next refresh exercises the grace window. The HTTP status, or
  /// null when no reply came.
  Future<int?> qaRefreshDiscardingReply() async {
    SessionTrail.step('qa: refresh, reply discarded');
    final refresh = await secureStorage.read(SecureStorageKey.refreshToken);
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final res = await _postRefresh(refresh);
      return res.statusCode;
    } on DioException {
      return null;
    }
  }

  /// Two refreshes with the same token sent together, around the app's
  /// lock (as two processes would). The pair from a 200 is stored. Both
  /// statuses, and whether the two 200s carried the same pair (compared
  /// here; never shown).
  Future<({int? first, int? second, bool samePair})> qaRaceRefresh() async {
    SessionTrail.step('qa: two refreshes at once');
    final refresh = await secureStorage.read(SecureStorageKey.refreshToken);
    if (refresh == null || refresh.isEmpty) {
      return (first: null, second: null, samePair: false);
    }
    Future<Response<dynamic>?> send() async {
      try {
        return await _postRefresh(refresh);
      } on DioException {
        return null;
      }
    }

    final replies = await Future.wait([send(), send()]);
    final ok = [
      for (final r in replies)
        if (r != null && (r.statusCode == 200 || r.statusCode == 201)) r,
    ];
    for (final r in ok) {
      if (await _storePair(r.data)) break;
    }
    String? refreshOf(Response<dynamic> r) {
      final d = r.data;
      final t = d is Map && d['data'] is Map ? d['data'] : d;
      return t is Map ? t['refresh_token']?.toString() : null;
    }

    return (
      first: replies[0]?.statusCode,
      second: replies[1]?.statusCode,
      samePair:
          ok.length == 2 &&
          refreshOf(ok[0]) != null &&
          refreshOf(ok[0]) == refreshOf(ok[1]),
    );
  }

  /// When the stored access token expires, if it is a JWT.
  Future<DateTime?> qaAccessExpiry() async {
    final t = await secureStorage.read(SecureStorageKey.accessToken);
    if (t == null || t.isEmpty) return null;
    try {
      return JwtDecoder.getExpirationDate(t).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<Response<dynamic>> _postRefresh(String refresh) => dio.post(
    '${EnvironmentConfig.apiUrl}${Endpoints.refreshToken}',
    data: {'refresh_token': refresh},
    options: Options(validateStatus: (_) => true),
  );

  Future<String?> _lockAndRefreshToken() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return secureStorage.read(SecureStorageKey.accessToken);
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await secureStorage.read(
        SecureStorageKey.refreshToken,
      );
      final success = await _refreshToken(refreshToken);

      if (success) {
        SessionTrail.step('token refreshed');
        return await secureStorage.read(SecureStorageKey.accessToken);
      } else {
        await _clearToken(_refreshFailure);
        return null;
      }
    } on _RefreshUnreachable {
      SessionTrail.step('refresh unreachable, session kept');
      // No connection (offline, DNS, timeout): the refresh token may be
      // perfectly valid — keep the session. Wiping it here logged drivers out
      // just for opening the app without internet; the request fails, the
      // offline card shows, and the next call once online refreshes normally.
      return null;
    } on _AccountRestrictedRefresh {
      // Refresh refused with 403 account_suspended / account_deleted: the
      // session isn't dead, the account is restricted. Keep the tokens (a
      // lifted suspension makes them usable again) and let the router show the
      // "contact the company" screen instead of logging the driver out.
      return null;
    } catch (e) {
      // Not a 401 from the server: no proof the session is dead.
      SessionTrail.step('refresh threw ${e.runtimeType}, session kept');
      return null;
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  bool _isRefreshTokenRequest(RequestOptions options) {
    return options.path.endsWith(Endpoints.refreshToken);
  }

  /// Sign-in calls: a 401 there is a wrong OTP (`INVALID_OTP`), not a dead
  /// session — refreshing would wipe tokens and fire the logout path.
  bool _isOtpRequest(RequestOptions options) {
    return options.path.endsWith(Endpoints.otpPhoneRequest) ||
        options.path.endsWith(Endpoints.phoneVerify);
  }

  /// Only a 401 means "this token is no longer good". 403 is the opposite —
  /// the token authenticated fine and the server refused the action anyway,
  /// which this API uses for real business outcomes: `documents_not_verified`
  /// on going online, and COD-blocked on accepting a messenger job (SCRUM-41
  /// §4). Treating those as an expired session sent the driver through a
  /// pointless refresh and, when it failed, wiped their tokens and logged them
  /// out — and swallowed the 403 the screens needed in order to explain what
  /// was actually wrong.
  bool _isUnauthorized(DioException e) {
    if (e.response == null) return false;

    final status = e.response?.statusCode;
    if (status == 401) return true;

    // Check for specific backend error format
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic> &&
          data['error'] == 'missing authorization header') {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> _clearToken(String reason) async {
    // Only a session that still had tokens is one the app ended. Once they
    // are wiped, every later 401 came back here and filed another
    // "SessionEnded: no refresh token stored" (7 for one driver in a week).
    final access = await secureStorage.read(SecureStorageKey.accessToken);
    final refresh = await secureStorage.read(SecureStorageKey.refreshToken);
    if ((access?.isNotEmpty ?? false) || (refresh?.isNotEmpty ?? false)) {
      SessionTrail.ended(reason);
    } else {
      SessionTrail.step('already signed out ($reason)');
    }
    await secureStorage.deleteAll();
    await authController?.refresh();
    await onTokenExpired?.call();
  }

  /// Exchanges [currentRefresh] for a new pair and stores it at once. True
  /// on success; false only when the server refused the token with a 401 —
  /// the one answer that ends the session. Anything else (offline, timeout,
  /// 5xx, 429, another 4xx, an unreadable reply) throws [_RefreshUnreachable]
  /// after the retries, and the tokens stay.
  Future<bool> _refreshToken(String? currentRefresh) async {
    if (currentRefresh?.isEmpty ?? true) {
      _refreshFailure = 'no refresh token stored';
      return false;
    }

    for (var attempt = 0; ; attempt++) {
      final Response<dynamic> response;
      try {
        response = await _postRefresh(currentRefresh!);
      } on DioException catch (e) {
        // No reply at all (offline, DNS, timeout, the app suspended mid-call).
        if (attempt < retryDelays.length && e.response == null) {
          SessionTrail.step('refresh no reply (${e.type.name}), retrying');
          await Future<void>.delayed(retryDelays[attempt]);
          continue;
        }
        throw const _RefreshUnreachable();
      }

      final status = response.statusCode ?? 0;
      if (status == 200 || status == 201) {
        if (await _storePair(response.data)) return true;
        // A 200 we can't read: the pair may have rotated server-side. The
        // same token gets the same pair back within the grace window.
        if (attempt < retryDelays.length) {
          SessionTrail.step('refresh answer unreadable, retrying');
          await Future<void>.delayed(retryDelays[attempt]);
          continue;
        }
        throw const _RefreshUnreachable();
      }

      final restriction = detectAccountRestriction(
        statusCode: status,
        data: response.data,
      );
      if (restriction != null) {
        AccountStatusNotifier.instance.markRestricted(restriction);
        throw const _AccountRestrictedRefresh();
      }

      if (status == 401) {
        // The server's own words, so Crashlytics' "SessionEnded" lines up
        // with the backend's refused-refresh log (user_id + time).
        _refreshFailure = 'refresh refused 401 ${_errorText(response.data)}';
        return false;
      }

      // 5xx / 429: a server problem, not a verdict on the token.
      if (attempt < retryDelays.length && (status >= 500 || status == 429)) {
        SessionTrail.step('refresh answered $status, retrying');
        await Future<void>.delayed(retryDelays[attempt]);
        continue;
      }
      SessionTrail.step('refresh answered $status, session kept');
      throw const _RefreshUnreachable();
    }
  }

  /// Stores the pair in [data] before anything else looks at it. False when
  /// it holds no pair.
  Future<bool> _storePair(Object? data) async {
    try {
      // Support both structured data wrapper and flat json
      final tokenData = data is Map && data.containsKey('data')
          ? data['data']
          : data;
      if (tokenData is! Map) return false;
      final model = AuthTokenModel.fromJson(
        Map<String, dynamic>.from(tokenData),
      );
      final accessToken = model.accessToken;
      final refreshToken = model.refreshToken;
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        return false;
      }
      await Future.wait([
        secureStorage.write(SecureStorageKey.accessToken, accessToken),
        secureStorage.write(SecureStorageKey.refreshToken, refreshToken),
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final options = requestOptions;
    requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    return await dio.fetch(options);
  }
}

/// What [AppDioRefreshTokenInterceptor.renewAfter401] did.
class TokenRenewal {
  const TokenRenewal.renewed(String this.token) : sessionEnded = false;
  const TokenRenewal.ended() : token = null, sessionEnded = true;
  const TokenRenewal.kept() : token = null, sessionEnded = false;

  /// The access token to retry with.
  final String? token;

  /// The refresh was refused: tokens are gone, the driver must sign in.
  final bool sessionEnded;
}

/// The backend's `error` text as sent (`token has been revoked`…), or ''.
/// Never a token: the refresh endpoint's errors don't echo it.
String _errorText(Object? data) {
  if (data is! Map) return '';
  final text = (data['error'] ?? data['message'] ?? data['code'])?.toString();
  if (text == null) return '';
  return text.length > 200 ? text.substring(0, 200) : text;
}

/// Internal signal: the refresh was refused because the account is restricted.
class _AccountRestrictedRefresh implements Exception {
  const _AccountRestrictedRefresh();
}

/// Internal signal: no verdict on the token (offline, 5xx, other non-401).
class _RefreshUnreachable implements Exception {
  const _RefreshUnreachable();
}

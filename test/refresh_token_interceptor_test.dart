import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/managers/api/refresh/app_dio_refreshtoken_interceptor.dart';

/// Storage holding whatever the app persisted earlier — during sign-in that is
/// the *previous* session's token, which is the whole point of these cases.
class _StubStorage implements SecureStorageManager {
  _StubStorage(this._values);

  final Map<SecureStorageKey, String> _values;

  @override
  Future<String?> read(SecureStorageKey key) async => _values[key];

  @override
  Future<bool> isContain(SecureStorageKey key) async =>
      _values.containsKey(key);

  @override
  Future<Map<String, String>> readAll() async =>
      _values.map((k, v) => MapEntry(k.name, v));

  @override
  Future<void> write(SecureStorageKey key, String? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> delete(SecureStorageKey key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

void main() {
  late AppDioRefreshTokenInterceptor interceptor;

  setUp(() {
    interceptor = AppDioRefreshTokenInterceptor(
      secureStorage: _StubStorage({
        SecureStorageKey.accessToken: 'stale-from-previous-session',
      }),
      dio: Dio(),
    );
  });

  test('leaves an Authorization header the caller set', () async {
    // The sign-in path: verifyOtp fetches the driver profile with the token the
    // verify call just returned, which is not in storage yet. Replacing it with
    // the stale one 401s, and the refresh that follows uses a refresh token the
    // sign-in already revoked — logging the driver straight back out.
    final options = RequestOptions(
      path: '/api/driver/profile',
      headers: {'Authorization': 'Bearer freshly-issued'},
    );

    await interceptor.onRequest(options, RequestInterceptorHandler());

    expect(options.headers['Authorization'], 'Bearer freshly-issued');
  });

  test('still attaches the stored token when the caller set none', () async {
    final options = RequestOptions(path: '/api/driver/profile');

    await interceptor.onRequest(options, RequestInterceptorHandler());

    expect(
      options.headers['Authorization'],
      'Bearer stale-from-previous-session',
    );
  });

  test('sends no Authorization when storage is empty', () async {
    final bare = AppDioRefreshTokenInterceptor(
      secureStorage: _StubStorage({}),
      dio: Dio(),
    );
    final options = RequestOptions(path: '/api/driver/profile');

    await bare.onRequest(options, RequestInterceptorHandler());

    expect(options.headers.containsKey('Authorization'), isFalse);
  });
}

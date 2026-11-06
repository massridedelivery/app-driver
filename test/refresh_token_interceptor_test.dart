import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/managers/api/refresh/app_dio_refreshtoken_interceptor.dart';
import 'package:massdrive/features/setting/presentation/widgets/session_qa_sheet.dart';

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

/// Answers `/auth/refresh` with [status] (and a new pair on 200); null
/// [status] = the server can't be reached.
class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter(int? status) : _statuses = [status];

  /// One answer per attempt; the last one repeats.
  _RefreshAdapter.sequence(this._statuses);

  final List<int?> _statuses;
  final sentRefresh = <Object?>[];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final code = _statuses[(calls - 1).clamp(0, _statuses.length - 1)];
    sentRefresh.add(options.data is Map ? options.data['refresh_token'] : null);
    if (code == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final body = code == 200
        ? {'access_token': 'new-access', 'refresh_token': 'new-refresh'}
        : {'error': 'token has been revoked'};
    return ResponseBody.fromString(
      jsonEncode(body),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('renewAfter401', () {
    late Map<SecureStorageKey, String> stored;
    late bool expired;

    AppDioRefreshTokenInterceptor make(_RefreshAdapter adapter) {
      stored = {
        SecureStorageKey.accessToken: 'sent-access',
        SecureStorageKey.refreshToken: 'old-refresh',
      };
      expired = false;
      final dio = Dio()..httpClientAdapter = adapter;
      return AppDioRefreshTokenInterceptor(
        secureStorage: _StubStorage(stored),
        dio: dio,
        onTokenExpired: () => expired = true,
        retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
      );
    }

    test('refreshes and hands back the new token to retry with', () async {
      final adapter = _RefreshAdapter(200);
      final r = await make(adapter).renewAfter401('sent-access');
      expect(r.token, 'new-access');
      expect(r.sessionEnded, isFalse);
      expect(stored[SecureStorageKey.refreshToken], 'new-refresh');
      expect(adapter.calls, 1);
    });

    test('a token already renewed by another request is reused', () async {
      final adapter = _RefreshAdapter(200);
      final i = make(adapter);
      stored[SecureStorageKey.accessToken] = 'renewed-meanwhile';
      final r = await i.renewAfter401('sent-access');
      expect(r.token, 'renewed-meanwhile');
      expect(adapter.calls, 0);
    });

    test('a refused refresh ends the session', () async {
      final r = await make(_RefreshAdapter(401)).renewAfter401('sent-access');
      expect(r.token, isNull);
      expect(r.sessionEnded, isTrue);
      expect(stored, isEmpty);
      expect(expired, isTrue);
    });

    test('two refreshes at once: one request, both get the new pair', () async {
      final adapter = _RefreshAdapter(200);
      final i = make(adapter);
      final results = await Future.wait([
        i.renewAfter401('sent-access'),
        i.renewAfter401('sent-access'),
      ]);
      expect(adapter.calls, 1);
      expect(results.map((r) => r.token), ['new-access', 'new-access']);
      expect(results.any((r) => r.sessionEnded), isFalse);
      expect(expired, isFalse);
    });

    test('app killed before the reply: the next launch sends the same '
        'refresh token (the grace window answers it)', () async {
      // Nothing was stored for the lost reply, so storage still holds the
      // token the server just rotated — exactly what it accepts for 60 s.
      final adapter = _RefreshAdapter(200);
      final r = await make(adapter).renewAfter401('sent-access');
      expect(adapter.sentRefresh, ['old-refresh']);
      expect(r.token, 'new-access');
    });

    test('a lost reply is retried with the same refresh token', () async {
      final adapter = _RefreshAdapter.sequence([null, 200]);
      final r = await make(adapter).renewAfter401('sent-access');
      expect(r.token, 'new-access');
      expect(adapter.sentRefresh, ['old-refresh', 'old-refresh']);
    });

    test('a 500 is retried, never a logout', () async {
      final adapter = _RefreshAdapter.sequence([500, 502, 200]);
      final r = await make(adapter).renewAfter401('sent-access');
      expect(r.token, 'new-access');
      expect(adapter.calls, 3);
      expect(expired, isFalse);
    });

    test('a server that keeps failing keeps the session', () async {
      final adapter = _RefreshAdapter(500);
      final r = await make(adapter).renewAfter401('sent-access');
      expect(r.sessionEnded, isFalse);
      expect(adapter.calls, 4);
      expect(stored[SecureStorageKey.refreshToken], 'old-refresh');
      expect(expired, isFalse);
    });

    test('only a 401 logs out — a 400 keeps the session', () async {
      final r = await make(_RefreshAdapter(400)).renewAfter401('sent-access');
      expect(r.sessionEnded, isFalse);
      expect(expired, isFalse);
    });

    group('QA sheet', () {
      test('is off unless the build passes QA_TOOLS=true', () {
        // `flutter test` runs without the define, like a store build.
        expect(kQaToolsEnabled, isFalse);
      });

      testWidgets('the sheet runs a refresh and never shows a token', (
        t,
      ) async {
        await initializeDateFormatting('th_TH');
        final i = make(_RefreshAdapter(200));
        await t.pumpWidget(
          MaterialApp(home: Scaffold(body: SessionQaSheet(interceptor: i))),
        );
        await t.pump();
        await t.tap(find.text('Refresh ตอนนี้'));
        await t.pumpAndSettle();
        expect(
          find.textContaining('สำเร็จ — ได้ token ใหม่'),
          findsOneWidget,
        );
        expect(find.textContaining('new-access'), findsNothing);
        expect(find.textContaining('new-refresh'), findsNothing);
      });

      test('a discarded reply leaves storage on the rotated token', () async {
        final adapter = _RefreshAdapter(200);
        final status = await make(adapter).qaRefreshDiscardingReply();
        expect(status, 200);
        expect(stored[SecureStorageKey.refreshToken], 'old-refresh');
        expect(stored[SecureStorageKey.accessToken], 'sent-access');
      });

      test('two raw refreshes: both answered, the pair is stored', () async {
        final adapter = _RefreshAdapter(200);
        final r = await make(adapter).qaRaceRefresh();
        expect(adapter.calls, 2);
        expect(adapter.sentRefresh, ['old-refresh', 'old-refresh']);
        expect((r.first, r.second, r.samePair), (200, 200, true));
        expect(stored[SecureStorageKey.refreshToken], 'new-refresh');
      });

      test(
        'a raw race that gets a 401 stores nothing, logs nothing out',
        () async {
          final r = await make(
            _RefreshAdapter.sequence([200, 401]),
          ).qaRaceRefresh();
          expect((r.first, r.second, r.samePair), (200, 401, false));
          expect(stored[SecureStorageKey.refreshToken], 'new-refresh');
          expect(expired, isFalse);
        },
      );
    });

    test('an unreachable server keeps the session', () async {
      final r = await make(_RefreshAdapter(null)).renewAfter401('sent-access');
      expect(r.token, isNull);
      expect(r.sessionEnded, isFalse);
      expect(stored[SecureStorageKey.accessToken], 'sent-access');
      expect(expired, isFalse);
    });
  });

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

  test(
    'a wrong OTP (401 on /auth/otp/verify) never wipes the session',
    () async {
      final storage = _StubStorage({SecureStorageKey.accessToken: 'kept'});
      final guarded = AppDioRefreshTokenInterceptor(
        secureStorage: storage,
        dio: Dio(),
      );
      final options = RequestOptions(path: '/auth/otp/verify');
      final err = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 401,
          data: {'error': 'รหัส OTP ไม่ถูกต้อง', 'code': 'INVALID_OTP'},
        ),
        type: DioExceptionType.badResponse,
      );

      final handler = ErrorInterceptorHandler();
      // The 401 goes straight on to the OTP screen, untouched.
      // ignore: invalid_use_of_protected_member
      final passedOn = handler.future.then(
        (_) => false,
        // next() completes with the error; a refresh + retry would resolve.
        onError: (Object _) => true,
      );

      await guarded.onError(err, handler);

      expect(await passedOn, isTrue);
      expect(await storage.read(SecureStorageKey.accessToken), 'kept');
    },
  );
}

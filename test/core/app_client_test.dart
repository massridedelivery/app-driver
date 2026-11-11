import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/managers/api/header_interceptor.dart';
import 'package:massdrive/core/utils/app_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AppClient.debugVersion = null);

  group('appVersionHeaderOf', () {
    test('version + build', () {
      expect(appVersionHeaderOf('1.0.2', '143'), '1.0.2+143');
      expect(appVersionHeaderOf('1.4.2-beta', ''), '1.4.2-beta');
    });

    test('anything the server would ignore is not sent', () {
      expect(appVersionHeaderOf('v1.0.2', '1'), isNull);
      expect(appVersionHeaderOf('1.0 beta', '1'), isNull);
      expect(appVersionHeaderOf('1.0.ไทย', '1'), isNull);
      expect(appVersionHeaderOf('1.${'0' * 70}', '1'), isNull);
      expect(appVersionHeaderOf('', ''), isNull);
    });
  });

  test('read once at startup from the package info', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Mass Drive',
      packageName: 'com.massapp.massdrive',
      version: '1.0.2',
      buildNumber: '143',
      buildSignature: '',
    );
    await AppClient.load();
    expect(AppClient.version, '1.0.2+143');
  });

  group('every API request', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<Map<String, dynamic>> headersOf() async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(HeaderInterceptor());
      await dio.get('/api/driver/profile');
      return adapter.requests.single.headers;
    }

    test('carries X-App-Version and X-App-Platform', () async {
      AppClient.debugVersion = '1.0.2+143';
      final headers = await headersOf();
      expect(headers['X-App-Version'], '1.0.2+143');
      // Tests run on the host; the app is ios or android.
      expect(headers['X-App-Platform'], anyOf('ios', 'android'));
    });

    test('no version known yet: only the platform', () async {
      final headers = await headersOf();
      expect(headers.containsKey('X-App-Version'), isFalse);
      expect(headers['X-App-Platform'], isNotNull);
    });
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/edit_profile/data/phone_link_api.dart';
import 'package:massdrive/features/edit_profile/presentation/widgets/change_phone_sheet.dart';
import 'package:pinput/pinput.dart';

class _Reply {
  const _Reply(this.status, this.body);
  final int status;
  final Object body;
}

class _Server implements HttpClientAdapter {
  _Server(this.replies);
  final Map<String, _Reply> replies;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = replies[options.path]!;
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PhoneLinkApi _api(_Server server) => PhoneLinkApi(
  Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server,
);

const _ok = {
  '/auth/phone/send': _Reply(200, {
    'message': 'OTP sent by SMS',
    'ref_id': 'ref-1234',
  }),
  '/auth/phone/verify': _Reply(200, {
    'phone': '+66812345678',
    'verified': true,
  }),
};

Future<PhoneChangeException> _refusal(Future<void> Function() call) async {
  try {
    await call();
  } on PhoneChangeException catch (e) {
    return e;
  }
  throw StateError('expected a PhoneChangeException');
}

/// The sheet's backend, answered in-process (no Dio I/O in widget tests).
class _FakeApi extends PhoneLinkApi {
  _FakeApi({this.send, this.check}) : super(Dio());
  final PhoneChangeException? send;
  final PhoneChangeException? check;
  final calls = <Object>[];

  @override
  Future<String> sendCode(String phone) async {
    calls.add(phone);
    if (send != null) throw send!;
    return 'ref-1234';
  }

  @override
  Future<String> verify({
    required String phone,
    required String otp,
    required String refId,
  }) async {
    calls.add({'phone': phone, 'otp': otp, 'ref_id': refId});
    if (check != null) throw check!;
    return toThaiE164(phone);
  }
}

void main() {
  group('POST /auth/phone/send + /auth/phone/verify', () {
    test('send E.164, then verify with the code and ref', () async {
      final server = _Server(_ok);
      final api = _api(server);
      expect(await api.sendCode('081-234-5678'), 'ref-1234');
      expect(
        await api.verify(phone: '0812345678', otp: '123456', refId: 'ref-1234'),
        '+66812345678',
      );
      expect(server.requests.map((r) => r.path), [
        '/auth/phone/send',
        '/auth/phone/verify',
      ]);
      expect(server.requests.first.data, {'phone': '+66812345678'});
      expect(server.requests.last.data, {
        'phone': '+66812345678',
        'otp': '123456',
        'ref_id': 'ref-1234',
      });
    });

    test('INVALID_PHONE: the server text, about the number', () async {
      final e = await _refusal(
        () => _api(
          _Server({
            '/auth/phone/send': const _Reply(400, {
              'code': 'INVALID_PHONE',
              'error': 'เบอร์โทรไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง',
            }),
          }),
        ).sendCode('0812345678'),
      );
      expect(e.message, 'เบอร์โทรไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง');
      expect(e.aboutPhone, isTrue);
    });

    test('PHONE_IN_USE is said in Thai', () async {
      final e = await _refusal(
        () => _api(
          _Server({
            '/auth/phone/send': const _Reply(409, {
              'code': 'PHONE_IN_USE',
              'error': 'this phone number is already used by another account',
            }),
          }),
        ).sendCode('0812345678'),
      );
      expect(e.message, PhoneChangeException.phoneInUse);
      expect(e.aboutPhone, isTrue);
    });

    test('OTP_RATE_LIMITED keeps retry_after', () async {
      final e = await _refusal(
        () => _api(
          _Server({
            '/auth/phone/send': const _Reply(429, {
              'code': 'OTP_RATE_LIMITED',
              'error': 'ขอรหัสเกินจำนวน กรุณาลองใหม่ใน 2 นาที',
              'retry_after': 90,
            }),
          }),
        ).sendCode('0812345678'),
      );
      expect(e.message, 'ขอรหัสเกินจำนวน กรุณาลองใหม่ใน 2 นาที');
      expect(e.retryAfter, const Duration(seconds: 90));
    });

    test(
      'a wrong code shows the server text; an expired one needs a new code',
      () async {
        final wrong = await _refusal(
          () => _api(
            _Server({
              '/auth/phone/verify': const _Reply(401, {
                'code': 'INVALID_OTP',
                'error': 'รหัส OTP ไม่ถูกต้อง',
                'attempts_left': 4,
              }),
            }),
          ).verify(phone: '0812345678', otp: '000000', refId: 'r'),
        );
        expect(wrong.message, 'รหัส OTP ไม่ถูกต้อง');
        expect(wrong.needsNewCode, isFalse);

        final expired = await _refusal(
          () => _api(
            _Server({
              '/auth/phone/verify': const _Reply(410, {
                'code': 'OTP_EXPIRED',
                'error': 'รหัส OTP หมดอายุ กรุณาขอรหัสใหม่',
              }),
            }),
          ).verify(phone: '0812345678', otp: '000000', refId: 'r'),
        );
        expect(expired.needsNewCode, isTrue);
      },
    );
  });

  group('ChangePhoneSheet', () {
    Future<void> pumpSheet(WidgetTester tester, PhoneLinkApi api) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangePhoneSheet(currentPhone: '+66899999999', api: api),
            ),
          ),
        );

    bool enabled(WidgetTester tester, String key) =>
        tester.widget<ElevatedButton>(find.byKey(ValueKey(key))).enabled;

    Future<void> typeNumber(WidgetTester tester, String number) async {
      await tester.enterText(
        find.byKey(const ValueKey('change-phone-field')),
        number,
      );
      await tester.pump();
    }

    Future<void> typeCode(WidgetTester tester, String code) => tester.enterText(
      find.descendant(
        of: find.byType(Pinput),
        matching: find.byType(EditableText),
      ),
      code,
    );

    Future<void> send(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('change-phone-send')));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a half-typed or unchanged number cannot be sent', (
      tester,
    ) async {
      final api = _FakeApi();
      await pumpSheet(tester, api);
      expect(find.text('เบอร์ปัจจุบัน 0899999999'), findsOneWidget);
      expect(enabled(tester, 'change-phone-send'), isFalse);

      await typeNumber(tester, '081234567');
      expect(enabled(tester, 'change-phone-send'), isFalse);
      expect(find.text(thaiPhoneHint), findsOneWidget);

      await typeNumber(tester, '0899999999');
      expect(enabled(tester, 'change-phone-send'), isFalse);
      expect(api.calls, isEmpty);
    });

    testWidgets('number taken: the reason under the field, still step one', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        _FakeApi(
          send: const PhoneChangeException(
            PhoneChangeException.phoneInUse,
            code: 'PHONE_IN_USE',
          ),
        ),
      );
      await typeNumber(tester, '0812345678');
      await send(tester);
      expect(find.text(PhoneChangeException.phoneInUse), findsOneWidget);
      expect(find.byType(Pinput), findsNothing);
    });

    testWidgets('code → the sheet closes with the saved number', (
      tester,
    ) async {
      final api = _FakeApi();
      String? result = 'unset';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showChangePhoneSheet(
                  context,
                  currentPhone: '+66899999999',
                  api: api,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await typeNumber(tester, '081-234-5678');
      await send(tester);
      expect(find.byType(Pinput), findsOneWidget);
      expect(find.textContaining('081•••5678'), findsOneWidget);
      expect(find.textContaining('Ref: 1234'), findsOneWidget);

      await typeCode(tester, '123456');
      await tester.pumpAndSettle();
      expect(result, '+66812345678');
      expect(api.calls, [
        '0812345678',
        {'phone': '0812345678', 'otp': '123456', 'ref_id': 'ref-1234'},
      ]);
    });

    testWidgets('a wrong code stays on the code step with the reason', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        _FakeApi(
          check: const PhoneChangeException(
            'รหัส OTP ไม่ถูกต้อง',
            code: 'INVALID_OTP',
          ),
        ),
      );
      await typeNumber(tester, '0812345678');
      await send(tester);
      await typeCode(tester, '000000');
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('change-phone-code-error')))
            .data,
        'รหัส OTP ไม่ถูกต้อง',
      );
      expect(find.text('ขอรหัสใหม่ได้ใน 01:00'), findsOneWidget);
      // Dispose the sheet so its countdown timer stops.
      await tester.pumpWidget(const SizedBox());
    });
  });
}

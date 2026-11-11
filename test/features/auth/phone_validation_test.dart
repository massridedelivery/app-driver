import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/auth/data/sources/auth_api_service_impl.dart';
import 'package:massdrive/features/auth/domain/entities/otp_response.dart';
import 'package:massdrive/features/auth/domain/otp_errors.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';
import 'package:massdrive/features/auth/domain/usecase/login_with_phone_usecase.dart';
import 'package:massdrive/features/auth/presentation/controllers/login_controller.dart';
import 'package:massdrive/features/auth/presentation/screens/login_screen.dart';
import 'package:massdrive/features/auth/presentation/widgets/auth_style.dart';
import 'package:massdrive/features/dependency_injection.dart';

const _serverText = 'เบอร์โทรไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';

class _Reply {
  const _Reply(this.status, this.body);
  final int status;
  final Object body;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final _Reply reply;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

class _NoRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// The OTP send, answered by the test.
class _Send extends LoginWithPhoneUseCase {
  _Send(this.answer) : super(_NoRepo());
  final Future<OtpResponse> Function() answer;
  final sent = <String>[];

  @override
  Future<OtpResponse> execute(String phone, String deviceId) {
    sent.add(phone);
    return answer();
  }
}

TextEditingValue _type(String text) =>
    const ThaiPhoneInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );

void main() {
  group('thai phone', () {
    test('what people type becomes local digits', () {
      for (final typed in [
        '0812345678',
        '081-234-5678',
        '081 234 5678',
        '+66812345678',
        '+66 81-234-5678',
      ]) {
        expect(thaiPhoneDigits(typed), '0812345678', reason: typed);
      }
    });

    test('valid = 10 digits starting with 0, length only', () {
      expect(isValidThaiPhone('0812345678'), isTrue);
      // Demo / store-review numbers pass, like on the backend.
      expect(isValidThaiPhone('0000000000'), isTrue);
      expect(isValidThaiPhone('081234567'), isFalse);
      expect(isValidThaiPhone('08123456789'), isFalse);
      expect(isValidThaiPhone('8123456789'), isFalse);
    });

    test('E.164 for the server, never the local form', () {
      expect(toThaiE164('0812345678'), '+66812345678');
      expect(toThaiE164('081-234-5678'), '+66812345678');
      expect(toThaiE164('+66812345678'), '+66812345678');
      expect(thaiPhoneForDisplay('+66812345678'), '0812345678');
      expect(thaiPhoneForDisplay('0812345678'), '0812345678');
    });

    test('the input keeps at most 10 digits, without dashes', () {
      expect(_type('081-234-5678').text, '0812345678');
      expect(_type('+66812345678').text, '0812345678');
      expect(_type('08123456789').text, '0812345678');
      const full = TextEditingValue(text: '0812345678');
      expect(
        const ThaiPhoneInputFormatter().formatEditUpdate(
          full,
          const TextEditingValue(text: '08123456789'),
        ),
        full,
      );
    });
  });

  group('POST /auth/otp/send', () {
    Future<(_Adapter, Object?)> send(String phone, _Reply reply) async {
      final server = _Adapter(reply);
      final api = AuthApiServiceImpl(
        Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = server,
      );
      try {
        await api.requestOtp(phone: phone, deviceId: 'd');
        return (server, null);
      } catch (e) {
        return (server, e);
      }
    }

    test('sends E.164', () async {
      final (server, error) = await send(
        '0812345678',
        const _Reply(200, {'ref_id': 'r', 'is_registered': true}),
      );
      expect(error, isNull);
      expect((server.requests.single.data as Map)['phone'], '+66812345678');
    });

    test('400 INVALID_PHONE → the server text, typed', () async {
      final (_, error) = await send(
        '0812345678',
        const _Reply(400, {'code': 'INVALID_PHONE', 'error': _serverText}),
      );
      expect(
        error,
        isA<InvalidPhoneException>().having(
          (e) => e.message,
          'message',
          _serverText,
        ),
      );
    });

    test('429 OTP_RATE_LIMITED is unchanged', () async {
      final (_, error) = await send(
        '0812345678',
        const _Reply(429, {
          'code': 'OTP_RATE_LIMITED',
          'error': 'ขอรหัสบ่อยเกินไป',
          'retry_after': 60,
        }),
      );
      expect(
        error,
        isA<OtpRateLimitedException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 60),
        ),
      );
    });
  });

  group('LoginScreen', () {
    tearDown(() => getIt.reset());

    Future<ProviderContainer> pump(WidgetTester tester, _Send send) async {
      getIt.registerSingleton<LoginWithPhoneUseCase>(send);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      return container;
    }

    bool buttonEnabled(WidgetTester tester) => tester
        .widget<AuthPrimaryButton>(find.byType(AuthPrimaryButton))
        .enabled;

    testWidgets('9 digits: button disabled, inline hint, nothing sent', (
      tester,
    ) async {
      final send = _Send(() => throw StateError('must not send'));
      await pump(tester, send);
      expect(find.text(thaiPhoneHint), findsNothing);

      await tester.enterText(find.byType(TextField), '081234567');
      await tester.pump();
      expect(buttonEnabled(tester), isFalse);
      expect(find.text(thaiPhoneHint), findsOneWidget);

      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pump();
      expect(send.sent, isEmpty);
    });

    testWidgets('a dashed number is accepted', (tester) async {
      final container = await pump(
        tester,
        _Send(() => throw StateError('unused')),
      );
      await tester.enterText(find.byType(TextField), '081-234-5678');
      await tester.pump();
      expect(buttonEnabled(tester), isTrue);
      expect(find.text(thaiPhoneHint), findsNothing);
      expect(container.read(loginControllerProvider).phoneNumber, '0812345678');
    });

    testWidgets(
      'server INVALID_PHONE: its text under the field, stays to edit',
      (tester) async {
        final send = _Send(() async {
          throw const InvalidPhoneException(_serverText);
        });
        final container = await pump(tester, send);
        await tester.enterText(find.byType(TextField), '0812345678');
        await tester.pump();
        await tester.tap(find.byType(AuthPrimaryButton));
        await tester.pump();
        await tester.pump();

        expect(send.sent, ['0812345678']);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('phone-helper'))).data,
          _serverText,
        );
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(container.read(loginControllerProvider).errorMessage, isNull);

        // Editing the number clears it.
        await tester.enterText(find.byType(TextField), '0812345679');
        await tester.pump();
        expect(find.text(_serverText), findsNothing);
      },
    );
  });
}

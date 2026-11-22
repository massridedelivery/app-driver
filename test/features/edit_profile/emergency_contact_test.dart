import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/edit_profile/data/emergency_contact_api.dart';
import 'package:massdrive/features/edit_profile/presentation/widgets/emergency_contact_sheet.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';

/// Answers every request with [status] / [body] and records what was sent.
class _Server implements HttpClientAdapter {
  _Server(this.status, this.body);
  final int status;
  final Object body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

EmergencyContactApi _api(_Server server) => EmergencyContactApi(
  Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server,
);

Future<EmergencyContactException> _refusal(Future<void> Function() call) async {
  try {
    await call();
  } on EmergencyContactException catch (e) {
    return e;
  }
  throw StateError('expected an EmergencyContactException');
}

/// The backend's 400 for a bad contact (internal/driver/profile/emergency.go).
_Server _invalid(String detail) =>
    _Server(400, {'error': 'invalid profile: emergency_contact.$detail'});

/// The sheet's backend, answered in-process (no Dio I/O in widget tests).
class _FakeApi extends EmergencyContactApi {
  _FakeApi({this.refusal}) : super(Dio());
  final EmergencyContactException? refusal;
  final calls = <Object>[];

  @override
  Future<void> save({
    required String name,
    required String phone,
    String relationship = '',
  }) async {
    calls.add({'name': name, 'phone': phone, 'relationship': relationship});
    if (refusal != null) throw refusal!;
  }

  @override
  Future<void> clear() async {
    calls.add('clear');
    if (refusal != null) throw refusal!;
  }
}

void main() {
  group('profile emergency_contact parsing', () {
    const base = {'user_id': 'u', 'full_name': 'สมชาย ใจดี'};

    test('reads name, phone and relationship', () {
      final p = DriverProfileEntity.fromJson({
        ...base,
        'emergency_contact': {
          'name': 'สมหญิง ใจดี',
          'phone': '+66812345678',
          'relationship': 'แม่',
        },
      });
      expect(
        p.savedEmergencyContact,
        const EmergencyContactEntity(
          name: 'สมหญิง ใจดี',
          phone: '+66812345678',
          relationship: 'แม่',
        ),
      );
    });

    test('relationship left out (omitempty) reads as blank', () {
      final p = DriverProfileEntity.fromJson({
        ...base,
        'emergency_contact': {'name': 'สมหญิง', 'phone': '+66812345678'},
      });
      expect(p.savedEmergencyContact?.relationship, '');
    });

    test('null, missing or blank phone means no contact', () {
      expect(
        DriverProfileEntity.fromJson({
          ...base,
          'emergency_contact': null,
        }).savedEmergencyContact,
        isNull,
      );
      expect(DriverProfileEntity.fromJson(base).savedEmergencyContact, isNull);
      expect(
        DriverProfileEntity.fromJson({
          ...base,
          'emergency_contact': {'name': '', 'phone': ''},
        }).savedEmergencyContact,
        isNull,
      );
    });

    test('row summary shows the phone as 08x', () {
      expect(
        emergencyContactSummary(
          const EmergencyContactEntity(
            name: 'สมหญิง ใจดี',
            phone: '+66812345678',
            relationship: 'แม่',
          ),
        ),
        'สมหญิง ใจดี (แม่) · 0812345678',
      );
      expect(
        emergencyContactSummary(
          const EmergencyContactEntity(name: 'สมหญิง', phone: '+66812345678'),
        ),
        'สมหญิง · 0812345678',
      );
      expect(emergencyContactSummary(null), isNull);
      expect(emergencyContactSummary(const EmergencyContactEntity()), isNull);
    });
  });

  group('validation', () {
    test('name is required and at most 100 characters', () {
      expect(validateEmergencyName(''), emergencyNameRequired);
      expect(validateEmergencyName('   '), emergencyNameRequired);
      expect(validateEmergencyName('ก' * 100), isNull);
      expect(validateEmergencyName('ก' * 101), emergencyNameTooLong);
      // Counted in runes like the server: "นี้" is three.
      expect(validateEmergencyName('นี้' * 33), isNull);
      expect(validateEmergencyName('นี้' * 34), emergencyNameTooLong);
    });

    test('phone is required and a 10-digit Thai mobile number', () {
      expect(validateEmergencyPhone(''), emergencyPhoneRequired);
      expect(validateEmergencyPhone('081234567'), thaiPhoneHint);
      expect(validateEmergencyPhone('0812345678'), isNull);
      expect(validateEmergencyPhone('081-234-5678'), isNull);
      expect(validateEmergencyPhone('+66812345678'), isNull);
    });

    test('relationship is optional, at most 50 characters', () {
      expect(validateEmergencyRelationship(''), isNull);
      expect(validateEmergencyRelationship(null), isNull);
      expect(validateEmergencyRelationship('ก' * 50), isNull);
      expect(
        validateEmergencyRelationship('ก' * 51),
        emergencyRelationshipTooLong,
      );
    });
  });

  group('request body', () {
    test('only emergency_contact, trimmed, phone in E.164', () {
      expect(
        emergencyContactBody(
          name: ' สมหญิง ใจดี ',
          phone: '081-234-5678',
          relationship: ' แม่ ',
        ),
        {
          'emergency_contact': {
            'name': 'สมหญิง ใจดี',
            'phone': '+66812345678',
            'relationship': 'แม่',
          },
        },
      );
    });

    test('save PUTs /api/driver/profile', () async {
      final server = _Server(200, {'user_id': 'u', 'full_name': 'x'});
      await _api(
        server,
      ).save(name: 'สมหญิง', phone: '0812345678', relationship: '');
      final req = server.requests.single;
      expect(req.method, 'PUT');
      expect(req.path, '/api/driver/profile');
      expect(req.data, {
        'emergency_contact': {
          'name': 'สมหญิง',
          'phone': '+66812345678',
          'relationship': '',
        },
      });
    });

    test('clear sends a blank phone', () async {
      final server = _Server(200, {'user_id': 'u', 'full_name': 'x'});
      await _api(server).clear();
      expect(server.requests.single.data, {
        'emergency_contact': {'name': '', 'phone': '', 'relationship': ''},
      });
    });
  });

  group('error mapping', () {
    test('bad phone → under the phone field', () async {
      final e = await _refusal(
        () => _api(
          _invalid('phone is not a mobile number'),
        ).save(name: 'ก', phone: '0812345678'),
      );
      expect(e.field, EmergencyContactField.phone);
      expect(e.message, thaiPhoneHint);
    });

    test('name missing vs too long → under the name field', () async {
      final missing = await _refusal(
        () => _api(
          _invalid('name is required'),
        ).save(name: ' ', phone: '0812345678'),
      );
      expect(missing.field, EmergencyContactField.name);
      expect(missing.message, emergencyNameRequired);

      final long = await _refusal(
        () => _api(
          _invalid('name is at most 100 characters'),
        ).save(name: 'ก' * 101, phone: '0812345678'),
      );
      expect(long.field, EmergencyContactField.name);
      expect(long.message, emergencyNameTooLong);
    });

    test('relationship too long → under the relationship field', () async {
      final e = await _refusal(
        () => _api(
          _invalid('relationship is at most 50 characters'),
        ).save(name: 'ก', phone: '0812345678', relationship: 'ข' * 51),
      );
      expect(e.field, EmergencyContactField.relationship);
      expect(e.message, emergencyRelationshipTooLong);
    });

    test('a code, when sent, wins over the text', () async {
      final e = await _refusal(
        () => _api(
          _Server(400, {'code': 'INVALID_PHONE', 'error': 'bad'}),
        ).save(name: 'ก', phone: '0812345678'),
      );
      expect(e.field, EmergencyContactField.phone);
    });

    test('another 400 → the form-wide fallback, never English', () async {
      final e = await _refusal(
        () => _api(
          _Server(400, {'error': 'invalid request body'}),
        ).save(name: 'ก', phone: '0812345678'),
      );
      expect(e.field, isNull);
      expect(e.message, EmergencyContactException.fallback);
    });

    test('5xx → the app-wide server message', () async {
      final e = await _refusal(
        () => _api(
          _Server(500, {'error': 'update failed'}),
        ).save(name: 'ก', phone: '0812345678'),
      );
      expect(e.field, isNull);
      expect(e.message, contains('เซิร์ฟเวอร์'));
    });
  });

  group('EmergencyContactSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      EmergencyContactApi api, {
      EmergencyContactEntity? current,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactSheet(current: current, api: api),
        ),
      ),
    );

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('emergency-save')));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a blank form is not sent', (tester) async {
      final api = _FakeApi();
      await pumpSheet(tester, api);
      expect(find.byKey(const ValueKey('emergency-clear')), findsNothing);
      await save(tester);
      expect(find.text(emergencyNameRequired), findsOneWidget);
      expect(find.text(emergencyPhoneRequired), findsOneWidget);
      expect(api.calls, isEmpty);
    });

    testWidgets('server refusal shows under the phone field', (tester) async {
      final api = _FakeApi(
        refusal: const EmergencyContactException(
          'เบอร์นี้ใช้ไม่ได้',
          field: EmergencyContactField.phone,
        ),
      );
      await pumpSheet(tester, api);
      await tester.enterText(
        find.byKey(const ValueKey('emergency-name')),
        'สมหญิง',
      );
      await tester.enterText(
        find.byKey(const ValueKey('emergency-phone')),
        '0812345678',
      );
      await save(tester);
      expect(api.calls, [
        {'name': 'สมหญิง', 'phone': '0812345678', 'relationship': ''},
      ]);
      expect(find.text('เบอร์นี้ใช้ไม่ได้'), findsOneWidget);
    });

    testWidgets('an existing contact is filled in as 08x and can be removed', (
      tester,
    ) async {
      final api = _FakeApi();
      EmergencyContactOutcome? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showEmergencyContactSheet(
                  context,
                  current: const EmergencyContactEntity(
                    name: 'สมหญิง',
                    phone: '+66812345678',
                    relationship: 'แม่',
                  ),
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
      expect(find.text('0812345678'), findsOneWidget);
      expect(find.text('แม่'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('emergency-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('emergency-clear-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, ['clear']);
      expect(result, EmergencyContactOutcome.cleared);
    });
  });
}

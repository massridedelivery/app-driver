import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/thai_date.dart';
import 'package:massdrive/features/document_registration/data/sources/document_registration_api.dart';
import 'package:massdrive/features/document_registration/domain/document_expiry.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/registration_controller.dart';
import 'package:massdrive/features/document_registration/presentation/screens/registration_checklist_screen.dart';
import 'package:massdrive/features/document_registration/presentation/states/registration_state.dart';
import 'package:massdrive/features/document_registration/presentation/widgets/expiry_date_field.dart';
import 'package:massdrive/features/profile/domain/profile_updates.dart';

DriverDocumentModel _doc(
  String type,
  String status, {
  String? reason,
  String? expiry,
  String? id,
}) => DriverDocumentModel(
  id: id ?? type,
  docType: type,
  imageUrl: '',
  status: status,
  rejectionReason: reason,
  expiryDate: expiry,
);

/// The backend's RFC3339 midnight-UTC form of [d].
String _rfc(DateTime d) => '${apiDate(d)}T00:00:00Z';

class _FakeRegistration extends RegistrationController {
  _FakeRegistration(this._state);
  final RegistrationState _state;

  @override
  RegistrationState build() => _state;

  @override
  Future<void> fetchStatus() async {}
}

Future<void> _pumpChecklist(
  WidgetTester tester,
  Map<DocumentType, DriverDocumentModel> docs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        registrationControllerProvider.overrideWith(
          () => _FakeRegistration(
            RegistrationState(
              overallStatus: RegistrationStateStatus.approved,
              selectedTier: KycTier.ride,
              remoteDocuments: docs,
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: RegistrationChecklistScreen()),
    ),
  );
  await tester.pump();
}

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object body = options.path.contains('upload-url')
        ? {
            'upload_url':
                'https://storage.test/p/x.pdf?sig=0123456789012345678901234567890123456789',
            'file_key': 'driver_doc/drv-1/x.pdf',
          }
        : options.path.contains('media/confirm')
        ? {'confirmed': true}
        : {'id': 'd1', 'doc_type': 'insurance', 'status': 'pending'};
    return ResponseBody.fromString(
      jsonEncode(body),
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
  tearDown(RequestedDocuments.ids.clear);

  group('dates', () {
    test('apiDate is Gregorian YYYY-MM-DD', () {
      expect(apiDate(DateTime(2027, 3, 9)), '2027-03-09');
    });

    test('the backend midnight-UTC expiry is read as its date', () {
      final doc = DriverDocumentModel.fromJson({
        'id': 'a',
        'doc_type': 'id_card',
        'image_url': '',
        'status': 'approved',
        'expiry_date': '2027-03-31T00:00:00Z',
      });
      expect(doc.expiryDay, DateTime(2027, 3, 31));
      expect(_doc('id_card', 'approved').expiryDay, isNull);
      expect(_doc('id_card', 'approved', expiry: 'soon').expiryDay, isNull);
    });

    test('daysUntil counts calendar days', () {
      final today = DateTime(2026, 11, 10, 23, 30);
      expect(daysUntil(DateTime(2026, 12, 10), today), 30);
      expect(daysUntil(DateTime(2026, 11, 9), today), -1);
    });
  });

  group('review state', () {
    final today = DateTime(2026, 11, 10);
    Map<DocumentType, DriverDocumentModel> approvedUntil(DateTime d) => {
      DocumentType.idCard: _doc('id_card', 'approved', expiry: _rfc(d)),
    };

    test('approved and expiring within 30 days → expiring', () {
      expect(
        reuploadStateOf(
          approvedUntil(DateTime(2026, 12, 10)),
          DocumentType.idCard,
          today: today,
        ),
        ReuploadState.expiring,
      );
      final open = openReuploads(
        approvedUntil(DateTime(2026, 11, 17)),
        today: today,
      );
      expect(open.single.state, ReuploadState.expiring);
      expect(open.single.expiry, DateTime(2026, 11, 17));
      expect(
        expiringLine(open.single),
        'หมดอายุ 17 พ.ย. 2569 · อัปโหลดฉบับใหม่ได้เลย',
      );
    });

    test('approved further out, or with no date → approved, not listed', () {
      expect(
        openReuploads(approvedUntil(DateTime(2026, 12, 11)), today: today),
        isEmpty,
      );
      expect(
        openReuploads({
          DocumentType.idCard: _doc('id_card', 'approved'),
        }, today: today),
        isEmpty,
      );
    });

    test('rejected on review vs. a new copy asked for', () {
      final docs = {
        DocumentType.idCard: _doc(
          'id_card',
          'rejected',
          reason: 'ภาพเบลอ',
          id: 'doc-1',
        ),
        DocumentType.insurance: _doc(
          'insurance',
          'rejected',
          reason: 'พ.ร.บ. หมดอายุแล้ว',
          id: 'doc-2',
        ),
      };
      var open = openReuploads(docs, today: today);
      expect(open.map(rejectedLine), [
        'ถูกปฏิเสธ: ภาพเบลอ',
        'ถูกปฏิเสธ: พ.ร.บ. หมดอายุแล้ว',
      ]);

      RequestedDocuments.addFromPush({
        'type': 'document_status',
        'reupload_requested': 'true',
        'document_ids': 'doc-2, doc-9',
      });
      open = openReuploads(docs, today: today);
      expect(open.map(rejectedLine), [
        'ถูกปฏิเสธ: ภาพเบลอ',
        'ขอเอกสารฉบับใหม่: พ.ร.บ. หมดอายุแล้ว',
      ]);
    });

    test('a rejected document whose expiry passed reads as a new copy', () {
      final open = openReuploads({
        DocumentType.insurance: _doc(
          'insurance',
          'rejected',
          reason: 'กรุณาส่งฉบับปีนี้',
          expiry: _rfc(DateTime(2026, 11, 1)),
        ),
      }, today: today);
      expect(rejectedLine(open.single), 'ขอเอกสารฉบับใหม่: กรุณาส่งฉบับปีนี้');
    });

    test('a review-result push records no ids', () {
      RequestedDocuments.addFromPush({
        'type': 'document_status',
        'status': 'rejected',
        'document_id': 'doc-1',
      });
      expect(RequestedDocuments.ids, isEmpty);
      RequestedDocuments.addFromPush({
        'type': 'document_status',
        'reupload_requested': 'true',
        'document_id': 'doc-1',
      });
      expect(RequestedDocuments.ids, {'doc-1'});
    });
  });

  test('both document pushes refresh the documents', () {
    expect(isDocumentStatusPush({'type': 'document_status'}), isTrue);
    expect(
      isDocumentStatusPush({
        'type': 'document_expiring',
        'document_id': 'd',
        'doc_type': 'insurance',
        'expiry_date': '2026-12-01',
        'days_left': '30',
      }),
      isTrue,
    );
    expect(isDocumentStatusPush({'type': 'payout_approved'}), isFalse);
  });

  group('screen', () {
    testWidgets('an expiring document is an amber row to renew', (
      tester,
    ) async {
      final now = DateTime.now();
      final expiry = DateTime(now.year, now.month, now.day + 10);
      await _pumpChecklist(tester, {
        DocumentType.idCard: _doc('id_card', 'approved', expiry: _rfc(expiry)),
        DocumentType.drivingLicense: _doc('driver_license', 'approved'),
      });
      expect(find.text('ผ่านการอนุมัติครบแล้ว'), findsNothing);
      expect(
        find.text('หมดอายุ ${formatThaiDate(expiry)} · อัปโหลดฉบับใหม่ได้เลย'),
        findsOneWidget,
      );
      expect(find.textContaining('ใกล้หมดอายุ'), findsOneWidget);
      // Approved documents with time left are not on the to-do list.
      expect(find.text('ใบขับขี่'), findsNothing);
    });

    testWidgets('the approved list shows each expiry date', (tester) async {
      final now = DateTime.now();
      final expiry = DateTime(now.year + 2, 3, 31);
      await _pumpChecklist(tester, {
        DocumentType.insurance: _doc(
          'insurance',
          'approved',
          expiry: _rfc(expiry),
        ),
      });
      expect(find.text('ผ่านการอนุมัติครบแล้ว'), findsOneWidget);
      expect(find.text('หมดอายุ ${formatThaiDate(expiry)}'), findsOneWidget);
    });
  });

  group('POST /api/driver/documents', () {
    late File file;
    setUp(() {
      file = File('${Directory.systemTemp.createTempSync().path}/doc.pdf')
        ..writeAsBytesSync([37, 80, 68, 70]);
    });

    Future<Map<String, dynamic>> register(DateTime? expiry) async {
      final server = _Adapter();
      final api = DocumentRegistrationApi(
        Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = server,
      )..newStorageDio = () => Dio()..httpClientAdapter = _Adapter();
      await api.uploadDocument(
        file,
        DocumentType.insurance,
        expiryDate: expiry,
      );
      final post = server.requests.lastWhere(
        (r) => r.method == 'POST' && r.path.endsWith('/api/driver/documents'),
      );
      return post.data as Map<String, dynamic>;
    }

    test('sends the date as Gregorian YYYY-MM-DD', () async {
      final body = await register(DateTime(2027, 3, 31));
      expect(body['expiry_date'], '2027-03-31');
    });

    test('no date → no expiry_date key', () async {
      final body = await register(null);
      expect(body.containsKey('expiry_date'), isFalse);
    });
  });

  group('ExpiryDateField', () {
    Future<void> pump(
      WidgetTester tester,
      DateTime? value,
      ValueChanged<DateTime?> onChanged,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpiryDateField(value: value, onChanged: onChanged),
        ),
      ),
    );

    testWidgets('shows the Buddhist-era date and can be cleared', (
      tester,
    ) async {
      DateTime? got = DateTime(2000);
      await pump(tester, DateTime(2027, 3, 31), (d) => got = d);
      expect(find.text('31 มี.ค. 2570'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('expiry-clear')));
      expect(got, isNull);
    });

    testWidgets('picking hands back a Gregorian date', (tester) async {
      DateTime? got;
      await pump(tester, null, (d) => got = d);
      expect(find.text('เลือกวันหมดอายุ'), findsOneWidget);
      await tester.tap(find.text('เลือกวันหมดอายุ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      // Opens a year ahead by default.
      expect(got?.year, now.year + 1);
    });

    test('years stay inside what the backend accepts', () {
      final years = expiryPickerYears(DateTime(2026, 11, 10));
      expect(years.first, 2025);
      expect(years.last, 2046);
      expect(expiryPickerYears(DateTime(2095)).last, 2100);
    });
  });
}

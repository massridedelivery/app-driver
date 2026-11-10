import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/registration_controller.dart';
import 'package:massdrive/features/document_registration/presentation/screens/registration_checklist_screen.dart';
import 'package:massdrive/features/document_registration/presentation/states/registration_state.dart';
import 'package:massdrive/features/home/presentation/widgets/reupload_banner.dart';

DriverDocumentModel _doc(String type, String status, [String? reason]) =>
    DriverDocumentModel(
      id: type,
      docType: type,
      imageUrl: '',
      status: status,
      rejectionReason: reason,
    );

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
  RegistrationState state,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        registrationControllerProvider.overrideWith(
          () => _FakeRegistration(state),
        ),
      ],
      child: const MaterialApp(home: RegistrationChecklistScreen()),
    ),
  );
  await tester.pump();
}

RegistrationState _approved(Map<DocumentType, DriverDocumentModel> docs) =>
    RegistrationState(
      overallStatus: RegistrationStateStatus.approved,
      selectedTier: KycTier.ride,
      remoteDocuments: docs,
    );

void main() {
  test('only rejected documents, in checklist order, reason trimmed', () {
    final rejected = rejectedDocuments([
      _doc('bank_passbook', 'rejected', ''),
      _doc('selfie', 'approved'),
      _doc('driver_license', 'pending'),
      _doc('id_card', 'rejected', ' ไฟล์เอกสารสูญหาย กรุณาอัปโหลดใหม่ '),
      _doc('unknown_type', 'rejected'),
    ]);
    expect(rejected, [
      (type: DocumentType.idCard, reason: 'ไฟล์เอกสารสูญหาย กรุณาอัปโหลดใหม่'),
      (type: DocumentType.bankPassbook, reason: null),
    ]);
    expect(rejectedNames(rejected), 'บัตรประชาชน, ข้อมูลบัญชีธนาคาร');
  });

  test('every backend doc_type maps to a type', () {
    expect(documentTypeFromApi('selfie'), DocumentType.profilePhoto);
    expect(
      documentTypeFromApi('public_transport_license'),
      DocumentType.publicDrivingLicense,
    );
    expect(
      documentTypeFromApi('vehicle_registration'),
      DocumentType.vehicleRegistration,
    );
    expect(documentTypeFromApi('vehicle_photo'), DocumentType.vehiclePhoto);
    expect(documentTypeFromApi('nope'), isNull);
  });

  testWidgets('approved, nothing sent back: the approved screen', (
    tester,
  ) async {
    await _pumpChecklist(
      tester,
      _approved({DocumentType.idCard: _doc('id_card', 'approved')}),
    );
    expect(find.text('เอกสารของคุณผ่านการอนุมัติแล้ว'), findsOneWidget);
  });

  testWidgets('approved with a document sent back: it can be re-uploaded', (
    tester,
  ) async {
    await _pumpChecklist(
      tester,
      _approved({
        DocumentType.idCard: _doc('id_card', 'approved'),
        DocumentType.insurance: _doc(
          'insurance',
          'rejected',
          'ไฟล์เอกสารสูญหาย กรุณาอัปโหลดใหม่',
        ),
      }),
    );
    expect(find.text('เอกสารของคุณผ่านการอนุมัติแล้ว'), findsNothing);
    expect(find.text('อัปโหลดเอกสารใหม่'), findsOneWidget);
    expect(find.text('พ.ร.บ. รถจักรยานยนต์ / ประกัน'), findsOneWidget);
    expect(
      find.text('ถูกปฏิเสธ: ไฟล์เอกสารสูญหาย กรุณาอัปโหลดใหม่'),
      findsOneWidget,
    );
    expect(find.text('บัตรประชาชน'), findsNothing);
  });

  testWidgets('a re-uploaded document waits as "รอตรวจสอบ", not red', (
    tester,
  ) async {
    await _pumpChecklist(
      tester,
      _approved({
        DocumentType.idCard: _doc('id_card', 'pending'),
        DocumentType.insurance: _doc('insurance', 'rejected', 'ภาพเบลอ'),
        DocumentType.drivingLicense: _doc('driver_license', 'approved'),
      }),
    );
    expect(find.text('อัปโหลดเอกสารใหม่'), findsOneWidget);
    expect(find.text('รอตรวจสอบ'), findsOneWidget);
    expect(find.text('ถูกปฏิเสธ: ภาพเบลอ'), findsOneWidget);
    // Approved documents are not listed here.
    expect(find.text('ใบขับขี่'), findsNothing);

    // Tapping a pending row does not reopen the upload.
    await tester.tap(find.text('รอตรวจสอบ'));
    await tester.pump();
    expect(find.text('ส่งแล้ว รอเจ้าหน้าที่ตรวจ'), findsOneWidget);
  });

  const pending = (
    type: DocumentType.idCard,
    state: ReuploadState.pending,
    reason: null,
  );
  const rejected = (
    type: DocumentType.insurance,
    state: ReuploadState.rejected,
    reason: 'x',
  );

  test('home alert: rejected wins, then waiting, then nothing', () {
    expect(documentAlertOf(const [pending, rejected]), (
      alert: DocumentAlert.rejected,
      rejected: 1,
    ));
    expect(documentAlertOf(const [pending]), (
      alert: DocumentAlert.waiting,
      rejected: 0,
    ));
    expect(documentAlertOf(const []), (alert: DocumentAlert.none, rejected: 0));
  });

  Future<void> pumpAlert(WidgetTester tester, Widget child) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      );

  testWidgets('status card line: red to re-upload, neutral while waiting', (
    tester,
  ) async {
    await pumpAlert(
      tester,
      const DocumentAlertLine(alert: DocumentAlert.rejected),
    );
    expect(find.text('มีเอกสารต้องอัปโหลดใหม่'), findsOneWidget);

    await pumpAlert(
      tester,
      const DocumentAlertLine(alert: DocumentAlert.waiting),
    );
    expect(find.text('เอกสารรอตรวจสอบ'), findsOneWidget);
  });

  testWidgets('profile badge: count when rejected, dot when waiting', (
    tester,
  ) async {
    await pumpAlert(
      tester,
      const DocumentMenuBadge(alert: DocumentAlert.rejected, rejected: 2),
    );
    expect(find.text('2'), findsOneWidget);

    await pumpAlert(
      tester,
      const DocumentMenuBadge(alert: DocumentAlert.waiting, rejected: 0),
    );
    expect(find.text('2'), findsNothing);
    expect(find.byType(Container), findsOneWidget);

    await pumpAlert(
      tester,
      const DocumentMenuBadge(alert: DocumentAlert.none, rejected: 0),
    );
    expect(find.byType(Container), findsNothing);
  });
}

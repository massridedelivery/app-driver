import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/constants/media_category.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/registration_controller.dart';
import 'package:massdrive/features/document_registration/presentation/states/registration_state.dart';

DriverDocumentModel _doc(String type, String status, {String? reason}) =>
    DriverDocumentModel(
      id: '$type-$status',
      docType: type,
      imageUrl: '$type.jpg',
      status: status,
      rejectionReason: reason,
    );

/// Registers an upload and returns [registered]; the list read afterwards
/// never answers, so the test sees the state before the refresh lands.
class _Repo implements DocumentRegistrationRepository {
  _Repo(this.registered);
  final DriverDocumentModel registered;
  final _never = Completer<RegistrationStatusInfo>();

  @override
  Future<DriverDocumentModel> uploadDocument(
    File file,
    DocumentType type, {
    MediaCategory category = MediaCategory.driverDoc,
    String? docNumber,
    String? docTypeOverride,
    DateTime? expiryDate,
  }) async => registered;

  @override
  Future<RegistrationStatusInfo> fetchRegistrationStatus() => _never.future;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('openReuploads', () {
    test(
      'rejected and pending rows stay, approved ones drop, in checklist order',
      () {
        final docs = {
          DocumentType.insurance: _doc('insurance', 'pending'),
          DocumentType.idCard: _doc('id_card', 'rejected', reason: ' ภาพเบลอ '),
          DocumentType.drivingLicense: _doc('driver_license', 'approved'),
          DocumentType.profilePhoto: _doc('selfie', 'approved'),
        };
        expect(openReuploads(docs), [
          (
            type: DocumentType.idCard,
            state: ReuploadState.rejected,
            reason: 'ภาพเบลอ',
            expiry: null,
            newCopy: false,
          ),
          (
            type: DocumentType.insurance,
            state: ReuploadState.pending,
            reason: null,
            expiry: null,
            newCopy: false,
          ),
        ]);
      },
    );

    // The reported bug: a re-upload stayed red after the back office approved
    // it. The list now holds one row per type, so its row is the answer.
    test('a re-upload that was approved is no longer open', () {
      final docs = {DocumentType.idCard: _doc('id_card', 'approved')};
      expect(openReuploads(docs), isEmpty);
      expect(
        reuploadStateOf(docs, DocumentType.idCard),
        ReuploadState.approved,
      );
    });

    test('nothing sent back means nothing open', () {
      expect(openReuploads(const {}), isEmpty);
      expect(reuploadStateOf(const {}, DocumentType.idCard), isNull);
    });
  });

  group('upload', () {
    late File photo;
    setUp(() async {
      photo = File('${Directory.systemTemp.createTempSync().path}/id.jpg');
      await photo.writeAsBytes([1, 2, 3]);
    });
    tearDown(() => getIt.reset());

    Future<RegistrationState> uploadAndPeek(
      DriverDocumentModel registered,
    ) async {
      getIt.registerSingleton<DocumentRegistrationRepository>(
        _Repo(registered),
      );
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sub = c.listen(registrationControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final notifier = c.read(registrationControllerProvider.notifier);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      notifier.state = RegistrationState(
        overallStatus: RegistrationStateStatus.approved,
        remoteDocuments: {
          DocumentType.idCard: _doc('id_card', 'rejected', reason: 'ภาพเบลอ'),
        },
      );
      unawaited(notifier.uploadDocument(photo, DocumentType.idCard));
      await pumpEventQueue();
      return c.read(registrationControllerProvider);
    }

    test('the returned row shows "รอตรวจสอบ" at once, not red', () async {
      final state = await uploadAndPeek(_doc('id_card', 'pending'));
      expect(state.remoteDocuments[DocumentType.idCard]!.status, 'pending');
      expect(openReuploads(state.remoteDocuments), [
        (
          type: DocumentType.idCard,
          state: ReuploadState.pending,
          reason: null,
          expiry: null,
          newCopy: false,
        ),
      ]);
    });

    test('a reply without a status still counts as sent', () async {
      final state = await uploadAndPeek(
        DriverDocumentModel(
          id: 'x',
          docType: 'id_card',
          imageUrl: '',
          status: '',
        ),
      );
      expect(state.remoteDocuments[DocumentType.idCard]!.status, 'pending');
    });
  });
}

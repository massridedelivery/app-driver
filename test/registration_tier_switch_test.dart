import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/registration_controller.dart';
import 'package:massdrive/features/document_registration/presentation/states/registration_state.dart';

/// setTier never touches the repository; it only has to exist for build().
class _UnusedRepository implements DocumentRegistrationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

DriverDocumentModel _doc(String type, String status) => DriverDocumentModel(
  id: type,
  docType: type,
  imageUrl: '$type.jpg',
  status: status,
);

void main() {
  setUp(() {
    getIt.registerSingleton<DocumentRegistrationRepository>(_UnusedRepository());
  });
  tearDown(() => getIt.reset());

  // Back from the checklist → pick another tier used to rebuild the state by
  // hand and drop remoteDocuments, so every uploaded doc lost its
  // "pending"/"approved" badge until the screen was reopened.
  test('going back to tier selection keeps the fetched document state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationControllerProvider.notifier);

    final remoteDocs = {
      DocumentType.profilePhoto: _doc('selfie', 'pending'),
      DocumentType.idCard: _doc('id_card', 'pending'),
      DocumentType.publicDrivingLicense:
          _doc('public_transport_license', 'pending'),
    };
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifier.state = RegistrationState(
      selectedTier: KycTier.ride,
      isProfileComplete: true,
      isPublicDrivingLicenseComplete: true,
      remoteDocuments: remoteDocs,
      uploadedDocuments: const {DocumentType.idCard: '/tmp/id.jpg'},
    );

    notifier.setTier(null);
    var state = container.read(registrationControllerProvider);
    expect(state.selectedTier, isNull);
    expect(state.remoteDocuments, remoteDocs);

    notifier.setTier(KycTier.both);
    state = container.read(registrationControllerProvider);
    expect(state.selectedTier, KycTier.both);
    expect(state.remoteDocuments, remoteDocs);
    expect(state.isPublicDrivingLicenseComplete, isTrue);
    expect(state.uploadedDocuments, {DocumentType.idCard: '/tmp/id.jpg'});
  });
}

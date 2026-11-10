import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart';
import 'package:massdrive/features/profile/domain/profile_updates.dart';

/// Documents still open after the admin sent them back — rejected, or sent
/// again and waiting for review — for the home banner. Read fresh each time
/// (never kept across sessions): on home, on resume, after an upload and on a
/// document-review push ([ProfileUpdates]). A failed read shows nothing
/// rather than an error on home.
final reuploadDocumentsProvider =
    FutureProvider.autoDispose<List<ReuploadItem>>((ref) async {
      void reload() => ref.invalidateSelf();
      ProfileUpdates.instance.addListener(reload);
      ref.onDispose(() => ProfileUpdates.instance.removeListener(reload));
      try {
        final docs = await getIt<DocumentRegistrationRepository>()
            .fetchDocuments();
        return openReuploads(documentsByType(docs));
      } catch (_) {
        return const [];
      }
    });

/// GET /api/driver/documents keyed by type. The backend returns one row per
/// doc_type (the newest upload), so this is a lookup, not a pick.
Map<DocumentType, DriverDocumentModel> documentsByType(
  Iterable<DriverDocumentModel> docs,
) => {
  for (final d in docs)
    if (documentTypeFromApi(d.docType) case final type?) type: d,
};

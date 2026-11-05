import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart';
import 'package:massdrive/features/profile/domain/profile_updates.dart';

/// Documents sent back for a re-upload, for the home banner. Re-read on a
/// document-review push ([ProfileUpdates]) and after the checklist refreshes;
/// a failed read shows nothing rather than an error on home.
final rejectedDocumentsProvider =
    FutureProvider.autoDispose<List<RejectedDocument>>((ref) async {
      void reload() => ref.invalidateSelf();
      ProfileUpdates.instance.addListener(reload);
      ref.onDispose(() => ProfileUpdates.instance.removeListener(reload));
      try {
        final docs = await getIt<DocumentRegistrationRepository>()
            .fetchDocuments();
        return rejectedDocuments(docs);
      } catch (_) {
        return const [];
      }
    });

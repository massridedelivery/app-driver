import 'package:flutter/foundation.dart';

/// Whether a push says the driver's documents changed: a review result or a
/// request for a new copy (`document_status`), or an approved document about
/// to expire (`document_expiring`). An approved selfie becomes the driver's
/// avatar_url on the backend, and a review can flip is_verified, so the
/// profile and the document list must be read again.
bool isDocumentStatusPush(Map<String, dynamic> data) =>
    switch (data['type']?.toString()) {
      'document_status' || 'document_expiring' => true,
      _ => false,
    };

/// Bumped when the profile changed server-side (a `document_status` push), so
/// the profile — photo, verification — is read again without a re-login.
class ProfileUpdates extends ChangeNotifier {
  ProfileUpdates._();
  static final ProfileUpdates instance = ProfileUpdates._();

  void notifyChanged() => notifyListeners();
}

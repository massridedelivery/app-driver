import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

/// Documents that carry an expiry date the driver can give on upload.
const expiringDocumentTypes = {
  DocumentType.idCard,
  DocumentType.drivingLicense,
  DocumentType.publicDrivingLicense,
  DocumentType.vehicleRegistration,
  DocumentType.insurance,
};

/// An approved document this close to its expiry is offered for renewal.
const expirySoonDays = 30;

/// Gregorian `YYYY-MM-DD` — what the backend reads.
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Whole days from [today] to [expiry] (negative once it has passed).
int daysUntil(DateTime expiry, DateTime today) => DateTime.utc(
  expiry.year,
  expiry.month,
  expiry.day,
).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

/// Documents the back office asked a new copy of, from `document_status`
/// pushes with `reupload_requested` (their `document_ids`). The list row is
/// a plain `rejected` one; this only picks the wording. Memory only — never
/// kept across sessions.
class RequestedDocuments {
  RequestedDocuments._();
  static final Set<String> ids = {};

  /// Records the ids of a `reupload_requested` push.
  static void addFromPush(Map<String, dynamic> data) {
    if (data['reupload_requested']?.toString() != 'true') return;
    final raw = data['document_ids'] ?? data['document_id'];
    if (raw == null) return;
    ids.addAll(
      raw.toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
    );
  }
}

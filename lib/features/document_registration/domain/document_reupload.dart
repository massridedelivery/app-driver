import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
import 'package:massdrive/core/utils/thai_date.dart';
import 'package:massdrive/features/document_registration/domain/document_expiry.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

/// The app's [DocumentType] for a backend `doc_type`, or null if unknown.
DocumentType? documentTypeFromApi(String docType) => switch (docType) {
  'selfie' => DocumentType.profilePhoto,
  'id_card' => DocumentType.idCard,
  'driver_license' => DocumentType.drivingLicense,
  'public_transport_license' => DocumentType.publicDrivingLicense,
  'vehicle_registration' => DocumentType.vehicleRegistration,
  'insurance' => DocumentType.insurance,
  'vehicle_photo' => DocumentType.vehiclePhoto,
  'bank_passbook' => DocumentType.bankPassbook,
  _ => null,
};

/// The document's name as the registration checklist shows it.
String documentTitle(DocumentType type) => switch (type) {
  DocumentType.profilePhoto => 'รูปถ่ายโปรไฟล์',
  DocumentType.idCard => 'บัตรประชาชน',
  DocumentType.drivingLicense => 'ใบขับขี่',
  DocumentType.publicDrivingLicense => 'ใบขับขี่สาธารณะ',
  DocumentType.vehicleRegistration => 'ข้อมูลรถ และ สมุดคู่มือ',
  DocumentType.vehiclePhoto => 'รูปถ่ายตัวรถ',
  DocumentType.insurance => 'พ.ร.บ. รถจักรยานยนต์ / ประกัน',
  DocumentType.bankPassbook => 'ข้อมูลบัญชีธนาคาร',
};

/// A document the admin sent back.
typedef RejectedDocument = ({DocumentType type, String? reason});

/// The rejected documents in checklist order. An approved driver can have
/// some: the admin asks for a re-upload (e.g. the stored file went missing)
/// while the account stays verified and keeps taking jobs.
List<RejectedDocument> rejectedDocuments(Iterable<DriverDocumentModel> docs) {
  final byType = <DocumentType, DriverDocumentModel>{
    for (final d in docs)
      if (documentTypeFromApi(d.docType) case final type?) type: d,
  };
  return [
    for (final type in DocumentType.values)
      if (byType[type] case final doc? when doc.status == 'rejected')
        (type: type, reason: _reason(doc.rejectionReason)),
  ];
}

String? _reason(String? raw) {
  final text = raw?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// Where a document on the re-upload screen stands.
enum ReuploadState {
  /// Sent back: rejected on review, or a new copy asked for.
  rejected,

  /// Sent again, waiting for review.
  pending,

  /// Approved, but runs out within [expirySoonDays]: a new copy may be sent
  /// early (it replaces this one once approved).
  expiring,

  approved,
}

/// One row of the re-upload screen.
typedef ReuploadItem = ({
  DocumentType type,
  ReuploadState state,
  String? reason,
  DateTime? expiry,

  /// [ReuploadState.rejected] because the back office asked for a new copy
  /// (expired, or a push said so) rather than on review.
  bool newCopy,
});

/// The re-upload screen's state of [type] in [docs] on [today], or null when
/// that row is missing or has a status this screen does not show.
ReuploadState? reuploadStateOf(
  Map<DocumentType, DriverDocumentModel> docs,
  DocumentType type, {
  DateTime? today,
}) {
  final doc = docs[type];
  switch (doc?.status) {
    case 'rejected':
      return ReuploadState.rejected;
    case 'pending':
      return ReuploadState.pending;
    case 'approved':
      final expiry = doc!.expiryDay;
      if (expiry != null &&
          daysUntil(expiry, today ?? DateTime.now()) <= expirySoonDays) {
        return ReuploadState.expiring;
      }
      return ReuploadState.approved;
    default:
      return null;
  }
}

/// The documents still to act on — sent back, sent again and waiting, or
/// approved but expiring — in checklist order.
///
/// [docs] is GET /api/driver/documents keyed by type: the backend returns only
/// the newest upload of each doc_type, so each type has exactly one row and
/// nothing is grouped or picked here.
List<ReuploadItem> openReuploads(
  Map<DocumentType, DriverDocumentModel> docs, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  return [
    for (final type in DocumentType.values)
      if (reuploadStateOf(docs, type, today: now) case final state?
          when state != ReuploadState.approved)
        _item(docs[type]!, type, state, now),
  ];
}

ReuploadItem _item(
  DriverDocumentModel doc,
  DocumentType type,
  ReuploadState state,
  DateTime today,
) {
  final expiry = doc.expiryDay;
  final newCopy =
      state == ReuploadState.rejected &&
      (RequestedDocuments.ids.contains(doc.id) ||
          (expiry != null && daysUntil(expiry, today) < 0));
  return (
    type: type,
    state: state,
    reason: _reason(doc.rejectionReason),
    expiry: expiry,
    newCopy: newCopy,
  );
}

/// The red line of a sent-back row.
String rejectedLine(ReuploadItem item) => item.newCopy
    ? 'ขอเอกสารฉบับใหม่: ${item.reason ?? 'กรุณาอัปโหลดฉบับใหม่'}'
    : 'ถูกปฏิเสธ: ${item.reason ?? 'กรุณาอัปโหลดใหม่'}';

/// The amber line of an expiring row.
String expiringLine(ReuploadItem item) =>
    'หมดอายุ ${formatThaiDate(item.expiry!)} · อัปโหลดฉบับใหม่ได้เลย';

/// The approved documents in checklist order, for the "all approved" screen.
List<DocumentType> approvedDocuments(
  Map<DocumentType, DriverDocumentModel> docs,
) => [
  for (final type in DocumentType.values)
    if (reuploadStateOf(docs, type) == ReuploadState.approved) type,
];

/// "บัตรประชาชน, ใบขับขี่" — the names for a one-line summary.
String rejectedNames(List<RejectedDocument> docs) =>
    docs.map((d) => documentTitle(d.type)).join(', ');

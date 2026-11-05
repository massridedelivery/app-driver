import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';
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

/// "บัตรประชาชน, ใบขับขี่" — the names for a one-line summary.
String rejectedNames(List<RejectedDocument> docs) =>
    docs.map((d) => documentTitle(d.type)).join(', ');

enum DocumentType {
  profilePhoto,
  idCard,
  drivingLicense,
  vehicleRegistration,
  vehiclePhoto,
  insurance,
  bankPassbook,
}

enum RegistrationStateStatus {
  pending,
  inReview,
  approved,
  rejected,
}

class RegistrationStatusInfo {
  final RegistrationStateStatus status;
  final List<String> rejectedReasons;
  final List<String> missingDocuments;

  RegistrationStatusInfo({
    required this.status,
    required this.rejectedReasons,
    required this.missingDocuments,
  });

  factory RegistrationStatusInfo.fromMap(Map<String, dynamic> map) {
    return RegistrationStatusInfo(
      status: _parseStatus(map['status']),
      rejectedReasons: List<String>.from(map['rejectedReasons'] ?? []),
      missingDocuments: List<String>.from(map['missingDocuments'] ?? []),
    );
  }

  static RegistrationStateStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'in_review':
        return RegistrationStateStatus.inReview;
      case 'approved':
        return RegistrationStateStatus.approved;
      case 'rejected':
        return RegistrationStateStatus.rejected;
      case 'pending':
      default:
        return RegistrationStateStatus.pending;
    }
  }
}

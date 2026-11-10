class DriverDocumentModel {
  final String id;
  final String docType;
  final String imageUrl;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;
  final String? docNumber;
  final String? uploadedAt;

  /// When the document runs out, as the backend sent it (RFC3339 at 00:00Z
  /// or YYYY-MM-DD). See [expiryDay].
  final String? expiryDate;

  DriverDocumentModel({
    required this.id,
    required this.docType,
    required this.imageUrl,
    required this.status,
    this.rejectionReason,
    this.docNumber,
    this.uploadedAt,
    this.expiryDate,
  });

  /// The expiry as a calendar date (Thai date — only the date part counts),
  /// or null when unknown or unreadable.
  DateTime? get expiryDay {
    final raw = expiryDate;
    if (raw == null || raw.length < 10) return null;
    final d = DateTime.tryParse(raw.substring(0, 10));
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    return DriverDocumentModel(
      id: json['id'] as String? ?? '',
      docType: json['doc_type'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      status: json['status'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      docNumber: json['doc_number'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
      expiryDate: json['expiry_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doc_type': docType,
      'image_url': imageUrl,
      'status': status,
      'rejection_reason': rejectionReason,
      'doc_number': docNumber,
      'uploaded_at': uploadedAt,
      'expiry_date': expiryDate,
    };
  }
}

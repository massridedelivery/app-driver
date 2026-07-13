class DriverDocumentModel {
  final String id;
  final String docType;
  final String imageUrl;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;
  final String? docNumber;
  final String? uploadedAt;

  DriverDocumentModel({
    required this.id,
    required this.docType,
    required this.imageUrl,
    required this.status,
    this.rejectionReason,
    this.docNumber,
    this.uploadedAt,
  });

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    return DriverDocumentModel(
      id: json['id'] as String? ?? '',
      docType: json['doc_type'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      status: json['status'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      docNumber: json['doc_number'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
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
    };
  }
}

/// A fare the driver claimed via the manual payment-override at job completion,
/// now awaiting (or having passed) finance review (SCRUM-86 §D, dev15).
///
/// `GET /api/driver/payments/held` → { items: [HeldFare], total }.
/// Rejected items stay in the list (not removed) so the driver sees the outcome.
class HeldFare {
  final String kind; // 'ride' | 'messenger' | ...
  final String id;
  final double amount;
  final String reason;
  final DateTime? claimedAt;
  final HeldFareStatus status;
  final DateTime? reviewedAt;
  final String? note;

  const HeldFare({
    required this.kind,
    required this.id,
    required this.amount,
    required this.reason,
    required this.status,
    this.claimedAt,
    this.reviewedAt,
    this.note,
  });

  factory HeldFare.fromJson(Map<String, dynamic> json) => HeldFare(
        kind: json['kind']?.toString() ?? '',
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason']?.toString() ?? '',
        status: HeldFareStatus.fromApi(json['status']?.toString()),
        claimedAt: DateTime.tryParse(json['claimed_at']?.toString() ?? ''),
        reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
        note: json['note']?.toString(),
      );
}

enum HeldFareStatus {
  pendingReview,
  approved,
  rejected;

  static HeldFareStatus fromApi(String? s) {
    switch (s) {
      case 'APPROVED':
        return HeldFareStatus.approved;
      case 'REJECTED':
        return HeldFareStatus.rejected;
      default:
        return HeldFareStatus.pendingReview;
    }
  }

  String get label => switch (this) {
        HeldFareStatus.pendingReview => 'รอตรวจสอบ',
        HeldFareStatus.approved => 'อนุมัติแล้ว',
        HeldFareStatus.rejected => 'ไม่อนุมัติ',
      };
}

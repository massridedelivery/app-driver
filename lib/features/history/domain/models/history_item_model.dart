enum PaymentType { grabPay, cash }

enum HistoryStatus { completed, cancelled }

enum ServiceType { ride, food }

class HistoryItemModel {
  final String id;
  final DateTime dateTime;
  final String title;
  final double? amount;
  final PaymentType? paymentType;
  final HistoryStatus status;
  final ServiceType serviceType;
  final String? rawType; // 'FARE_PAYMENT', 'COMMISSION_DEDUCTION', 'TOPUP', 'WITHDRAWAL', etc.

  /// Trip/job this transaction belongs to (`job_id`), used to load the trip
  /// detail. Null for non-trip entries (top-up, withdrawal).
  final String? jobId;

  HistoryItemModel({
    required this.id,
    required this.dateTime,
    required this.title,
    this.amount,
    this.paymentType,
    required this.status,
    this.serviceType = ServiceType.ride,
    this.rawType,
    this.jobId,
  });
}


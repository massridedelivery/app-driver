enum PaymentType { grabPay, cash }

enum HistoryStatus { completed, cancelled }

class HistoryItemModel {
  final String id;
  final DateTime dateTime;
  final String title;
  final double? amount;
  final PaymentType? paymentType;
  final HistoryStatus status;

  HistoryItemModel({
    required this.id,
    required this.dateTime,
    required this.title,
    this.amount,
    this.paymentType,
    required this.status,
  });
}

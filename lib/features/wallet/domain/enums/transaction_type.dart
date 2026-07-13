/// Represents the nature of the financial movement in the wallet.
enum TransactionType {
  /// Earnings added after completing a trip or delivery.
  farePayment,

  /// Platform fee subtracted (usually paired with a fare payment).
  commissionDeduction,

  /// Funds added via bank transfer slip or payment gateway.
  topup,

  /// Funds transferred out to the driver's bank account.
  withdrawal,

  /// Incentive rewards (e.g., Quest completion).
  bonus,

  /// Manual correction (e.g., compensation).
  adjustment;

  /// Parses a raw API string (e.g. "FARE_PAYMENT") into a [TransactionType].
  /// Returns [TransactionType.adjustment] as a safe fallback for unknown values.
  static TransactionType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'FARE_PAYMENT':
        return TransactionType.farePayment;
      case 'COMMISSION_DEDUCTION':
        return TransactionType.commissionDeduction;
      case 'TOPUP':
        return TransactionType.topup;
      case 'WITHDRAWAL':
        return TransactionType.withdrawal;
      case 'BONUS':
        return TransactionType.bonus;
      case 'ADJUSTMENT':
      default:
        return TransactionType.adjustment;
    }
  }

  /// Converts back to the API string representation.
  String toApiString() {
    switch (this) {
      case TransactionType.farePayment:
        return 'FARE_PAYMENT';
      case TransactionType.commissionDeduction:
        return 'COMMISSION_DEDUCTION';
      case TransactionType.topup:
        return 'TOPUP';
      case TransactionType.withdrawal:
        return 'WITHDRAWAL';
      case TransactionType.bonus:
        return 'BONUS';
      case TransactionType.adjustment:
        return 'ADJUSTMENT';
    }
  }

  /// Whether this transaction type adds funds to the wallet.
  bool get isCredit {
    switch (this) {
      case TransactionType.farePayment:
      case TransactionType.topup:
      case TransactionType.bonus:
      case TransactionType.adjustment:
        return true;
      case TransactionType.commissionDeduction:
      case TransactionType.withdrawal:
        return false;
    }
  }

  /// Whether this transaction type deducts funds from the wallet.
  bool get isDebit => !isCredit;
}

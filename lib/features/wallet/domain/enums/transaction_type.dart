/// Row label for [TransactionType.cancellationFeeCollected].
const cancellationFeeCollectedLabel = 'ค่ายกเลิกที่เก็บแทนบริษัท';

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
  adjustment,

  /// `marketing_expense`: the platform-funded promo on a job. It records the
  /// part of the fare the company paid instead of the customer — already in
  /// the fare and the job's driver_net, so it is not extra income.
  promoDiscount,

  /// `CANCELLATION_FEE_COLLECTED` (BE PR #15): a customer's earlier cancel
  /// fee the driver took in cash on a later job. Negative — cash held for the
  /// company, owed back like the cash-fare debt. Never on QR jobs.
  cancellationFeeCollected;

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
      case 'MARKETING_EXPENSE':
        return TransactionType.promoDiscount;
      case 'CANCELLATION_FEE_COLLECTED':
        return TransactionType.cancellationFeeCollected;
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
      case TransactionType.promoDiscount:
        return 'MARKETING_EXPENSE';
      case TransactionType.cancellationFeeCollected:
        return 'CANCELLATION_FEE_COLLECTED';
    }
  }

  /// Whether this transaction type adds funds to the wallet.
  bool get isCredit {
    switch (this) {
      case TransactionType.farePayment:
      case TransactionType.topup:
      case TransactionType.bonus:
      case TransactionType.adjustment:
      case TransactionType.promoDiscount:
        return true;
      case TransactionType.commissionDeduction:
      case TransactionType.withdrawal:
      case TransactionType.cancellationFeeCollected:
        return false;
    }
  }

  /// Whether this transaction type deducts funds from the wallet.
  bool get isDebit => !isCredit;
}

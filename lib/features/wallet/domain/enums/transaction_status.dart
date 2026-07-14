/// Represents the lifecycle state of a wallet transaction.
enum TransactionStatus {
  /// Transaction is created but not yet finalized
  /// (e.g., bank slip awaiting admin review).
  pending,

  /// Funds have been successfully moved and balance is updated.
  completed,

  /// Transaction was aborted due to a system or payment error.
  failed,

  /// Transaction was denied (e.g., invalid bank slip).
  rejected;

  /// Parses a raw API string (e.g. "COMPLETED") into a [TransactionStatus].
  /// Returns [TransactionStatus.pending] as a safe fallback for unknown values.
  static TransactionStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'REJECTED':
        return TransactionStatus.rejected;
      case 'PENDING':
      default:
        return TransactionStatus.pending;
    }
  }

  /// Converts back to the API string representation.
  String toApiString() {
    switch (this) {
      case TransactionStatus.pending:
        return 'PENDING';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.failed:
        return 'FAILED';
      case TransactionStatus.rejected:
        return 'REJECTED';
    }
  }

  /// Whether this status means the wallet balance has been updated.
  bool get affectsBalance => this == TransactionStatus.completed;

  /// Whether this status represents a terminal (final) state.
  bool get isTerminal {
    switch (this) {
      case TransactionStatus.completed:
      case TransactionStatus.failed:
      case TransactionStatus.rejected:
        return true;
      case TransactionStatus.pending:
        return false;
    }
  }
}

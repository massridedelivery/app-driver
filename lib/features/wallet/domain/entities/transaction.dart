import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

/// Domain entity representing a single wallet transaction.
class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final TransactionStatus status;
  final String description;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  /// Whether the amount adds funds to the wallet.
  bool get isCredit => amount >= 0;

  /// Whether the amount deducts funds from the wallet.
  bool get isDebit => amount < 0;

  /// Absolute value of the amount for display purposes.
  double get absoluteAmount => amount.abs();
}

/// Paginated result returned by the transaction list endpoint.
class TransactionListResult {
  final List<Transaction> transactions;

  /// Total number of records (before pagination).
  final int total;

  const TransactionListResult({
    required this.transactions,
    required this.total,
  });
}

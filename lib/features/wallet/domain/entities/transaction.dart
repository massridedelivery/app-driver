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

  // Additional fields from API
  final String? jobId;
  final String? orderId;
  final String? userId;
  final String? counterpartyId;
  final String? currency;
  final String? paymentMethod;
  final String? metadata;
  final double? commission;
  final double? discount;
  final double? platformFee;
  final double? subtotal;
  final DateTime? completedAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    required this.createdAt,
    this.jobId,
    this.orderId,
    this.userId,
    this.counterpartyId,
    this.currency,
    this.paymentMethod,
    this.metadata,
    this.commission,
    this.discount,
    this.platformFee,
    this.subtotal,
    this.completedAt,
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
  final int limit;
  final int offset;

  const TransactionListResult({
    required this.transactions,
    required this.total,
    this.limit = 20,
    this.offset = 0,
  });
}


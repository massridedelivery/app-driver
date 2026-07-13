import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';

abstract class TransactionRepository {
  /// Fetches a paginated, filterable list of wallet transactions.
  /// Corresponds to GET /api/driver/earnings/transactions
  Future<TransactionListResult> getTransactions(TransactionQuery query);
}

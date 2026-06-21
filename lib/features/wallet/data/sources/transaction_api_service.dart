import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';

abstract class TransactionApiService {
  /// Calls GET /api/driver/earnings/transactions
  Future<Map<String, dynamic>> getTransactions(TransactionQuery query);
}

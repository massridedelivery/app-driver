import 'package:injectable/injectable.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactionListUseCase {
  final TransactionRepository _repository;

  GetTransactionListUseCase(this._repository);

  Future<TransactionListResult> execute(TransactionQuery query) {
    return _repository.getTransactions(query);
  }
}

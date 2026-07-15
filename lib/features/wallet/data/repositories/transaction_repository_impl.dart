import 'package:injectable/injectable.dart';
import 'package:massdrive/features/wallet/data/models/transaction_model.dart';
import 'package:massdrive/features/wallet/data/sources/transaction_api_service.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/repositories/transaction_repository.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionApiService _apiService;

  TransactionRepositoryImpl(this._apiService);

  @override
  Future<TransactionListResult> getTransactions(TransactionQuery query) async {
    final json = await _apiService.getTransactions(query);
    return TransactionListModel.fromJson(json).toEntity();
  }
}

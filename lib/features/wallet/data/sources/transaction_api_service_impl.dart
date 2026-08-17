import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
import 'package:massdrive/features/wallet/data/sources/transaction_api_service.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';

@LazySingleton(as: TransactionApiService)
class TransactionApiServiceImpl implements TransactionApiService {
  final Dio _dio;

  TransactionApiServiceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getTransactions(TransactionQuery query) async {
    try {
      final response = await _dio.get(
        Endpoints.driverEarningsTransactions,
        queryParameters: query.toQueryParameters(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Never substitute a canned ledger — the driver would read invented
      // trips, commissions and payouts as their own.
      ApiError.surface(e, 'Failed to fetch transactions');
    }
  }
}

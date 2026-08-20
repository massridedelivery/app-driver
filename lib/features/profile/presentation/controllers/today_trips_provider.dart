import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/usecases/get_transaction_list_usecase.dart';

/// Today's completed trips (FARE_PAYMENT) for the profile screen — a list plus
/// its count. autoDispose so it re-fetches each time the profile is opened.
final todayTripsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final now = DateTime.now();
  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  final today = ymd(now);
  final result = await getIt<GetTransactionListUseCase>().execute(
    TransactionQuery(
      startDate: today,
      endDate: today,
      type: 'FARE_PAYMENT',
      limit: 50,
    ),
  );
  return result.transactions;
});

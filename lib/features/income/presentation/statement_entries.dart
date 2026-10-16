import 'package:massdrive/common/widgets/earnings/day_job_groups.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

/// One line of the รายการทั้งหมด statement.
sealed class StatementEntry {
  const StatementEntry();
}

/// "19 กันยายน 2026".
class StatementDay extends StatementEntry {
  const StatementDay(this.date);
  final DateTime date;
}

/// A wallet movement that isn't tied to a job (top-up, withdrawal…).
class StatementTxn extends StatementEntry {
  const StatementTxn(this.transaction);
  final Transaction transaction;
}

/// Everything one job moved on a day — fare in, commission out — as one card.
class StatementJob extends StatementEntry {
  const StatementJob(this.jobId, this.transactions);
  final String jobId;

  /// Fare first, then deductions, then anything else.
  final List<Transaction> transactions;

  /// The newest movement's time, which places the card in the list.
  DateTime get time => transactions
      .map((t) => t.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  /// First non-empty pickup address among the job's rows.
  String? get pickupAddress {
    for (final t in transactions) {
      final a = t.pickupAddress?.trim();
      if (a != null && a.isNotEmpty) return a;
    }
    return null;
  }

  /// `ride` | `food` | `messenger` when any row says so.
  String? get service {
    for (final t in transactions) {
      if (t.service != null && t.service!.isNotEmpty) return t.service;
    }
    return null;
  }
}

int _order(TransactionType t) => switch (t) {
  TransactionType.farePayment => 0,
  TransactionType.commissionDeduction => 1,
  _ => 2,
};

/// Which rows a statement shows.
enum StatementScope {
  /// Every movement.
  all,

  /// Only what belongs to a job — fares, commissions (รายการทั้งหมด).
  jobs,

  /// Only wallet movements with no job — top-ups, adjustments, withdrawals…
  /// (ประวัติเครดิต).
  wallet,
}

bool _inScope(Transaction t, StatementScope scope) {
  final hasJob = (t.jobId?.trim() ?? '').isNotEmpty;
  return switch (scope) {
    StatementScope.all => true,
    StatementScope.jobs => hasJob,
    StatementScope.wallet => !hasJob,
  };
}

/// Builds the statement from newest-first transactions: a day header when
/// the (local) day changes, and within a day every row of the same job folded
/// into one [StatementJob] at the position of its newest row.
List<StatementEntry> buildStatement(
  List<Transaction> transactions, {
  StatementScope scope = StatementScope.all,
}) => [
  for (final e in groupByDayAndJob<Transaction>(
    transactions.where((t) => _inScope(t, scope)),
    time: (t) => t.createdAt,
    jobId: (t) => t.jobId,
  ))
    switch (e) {
      DayHeader(:final date) => StatementDay(date),
      SingleRow(:final item) => StatementTxn(item),
      JobGroup(:final jobId, :final items) => StatementJob(
        jobId,
        [...items]..sort((a, b) => _order(a.type).compareTo(_order(b.type))),
      ),
    },
];

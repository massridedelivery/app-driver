import 'package:intl/intl.dart';
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

/// Builds the statement from newest-first transactions: a day header when
/// the (local) day changes, and within a day every row of the same job folded
/// into one [StatementJob] at the position of its newest row.
List<StatementEntry> buildStatement(List<Transaction> transactions) {
  final dayKey = DateFormat('yyyy-MM-dd');
  final out = <StatementEntry>[];
  String? lastDay;
  // Jobs already placed today, so later rows of the same job join that card.
  final jobsToday = <String, List<Transaction>>{};
  for (final t in transactions) {
    final local = t.createdAt.toLocal();
    final key = dayKey.format(local);
    if (key != lastDay) {
      out.add(StatementDay(local));
      lastDay = key;
      jobsToday.clear();
    }
    final job = t.jobId?.trim() ?? '';
    if (job.isEmpty) {
      out.add(StatementTxn(t));
      continue;
    }
    final rows = jobsToday[job];
    if (rows != null) {
      rows.add(t);
    } else {
      final list = [t];
      jobsToday[job] = list;
      out.add(StatementJob(job, list));
    }
  }
  for (final e in out) {
    if (e is StatementJob) {
      e.transactions.sort((a, b) => _order(a.type).compareTo(_order(b.type)));
    }
  }
  return out;
}

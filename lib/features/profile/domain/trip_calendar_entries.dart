import 'package:massdrive/features/history/domain/models/trip_summary.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

/// One completed job on the income schedule.
class CalendarTrip {
  const CalendarTrip({
    required this.jobId,
    required this.time,
    required this.net,
    this.vehicleTypeName,
    this.service,
  });

  final String jobId;
  final DateTime time;

  /// What the driver earned: the job's `driver_net` from the backend, else
  /// its fare and commission rows as the ledger booked them.
  final double net;
  final String? vehicleTypeName;

  /// `ride` | `food` | `messenger` from the fare row.
  final String? service;
}

/// The range's jobs, newest first, from its ledger rows. A job needs a fare
/// row; failed / rejected rows are left out; the promo row is ignored (it is
/// the company's share of the fare, not extra income).
List<CalendarTrip> calendarTrips(
  Iterable<Transaction> txns,
  Map<String, TripSummary> trips,
) {
  final byJob = <String, List<Transaction>>{};
  for (final t in txns) {
    final id = t.jobId?.trim() ?? '';
    if (id.isEmpty) continue;
    if (t.status == TransactionStatus.failed ||
        t.status == TransactionStatus.rejected) {
      continue;
    }
    if (t.type != TransactionType.farePayment &&
        t.type != TransactionType.commissionDeduction) {
      continue;
    }
    (byJob[id] ??= []).add(t);
  }
  final out = <CalendarTrip>[];
  byJob.forEach((id, rows) {
    final fares = rows.where((t) => t.type == TransactionType.farePayment);
    if (fares.isEmpty) return;
    out.add(
      CalendarTrip(
        jobId: id,
        time: fares.first.createdAt,
        net:
            trips[id]?.driverNet?.toDouble() ??
            rows.fold<double>(0, (sum, t) => sum + t.amount),
        vehicleTypeName: trips[id]?.vehicleTypeName,
        service: fares.first.service,
      ),
    );
  });
  out.sort((a, b) => b.time.compareTo(a.time));
  return out;
}

/// The schedule's headline: the sum of its jobs' net earnings.
double calendarNet(Iterable<CalendarTrip> trips) =>
    trips.fold<double>(0, (sum, t) => sum + t.net);

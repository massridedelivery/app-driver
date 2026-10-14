import 'package:intl/intl.dart';

/// A line of a date-grouped earnings list.
sealed class DayJobEntry<T> {
  const DayJobEntry();
}

/// The (local) day header.
class DayHeader<T> extends DayJobEntry<T> {
  const DayHeader(this.date);
  final DateTime date;
}

/// A row that isn't tied to a job.
class SingleRow<T> extends DayJobEntry<T> {
  const SingleRow(this.item);
  final T item;
}

/// Every row of one job on one day.
class JobGroup<T> extends DayJobEntry<T> {
  const JobGroup(this.jobId, this.items);
  final String jobId;
  final List<T> items;
}

/// Groups newest-first [items]: a [DayHeader] when the local day changes,
/// and within a day every item of the same job folded into one [JobGroup]
/// at the position of its newest item. Items without a job stay single.
List<DayJobEntry<T>> groupByDayAndJob<T>(
  Iterable<T> items, {
  required DateTime Function(T) time,
  required String? Function(T) jobId,
}) {
  final dayKey = DateFormat('yyyy-MM-dd');
  final out = <DayJobEntry<T>>[];
  String? lastDay;
  final jobsToday = <String, List<T>>{};
  for (final item in items) {
    final local = time(item).toLocal();
    final key = dayKey.format(local);
    if (key != lastDay) {
      out.add(DayHeader<T>(local));
      lastDay = key;
      jobsToday.clear();
    }
    final job = jobId(item)?.trim() ?? '';
    if (job.isEmpty) {
      out.add(SingleRow<T>(item));
      continue;
    }
    final rows = jobsToday[job];
    if (rows != null) {
      rows.add(item);
    } else {
      final list = <T>[item];
      jobsToday[job] = list;
      out.add(JobGroup<T>(job, list));
    }
  }
  return out;
}

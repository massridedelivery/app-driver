import 'package:intl/intl.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/core/utils/thai_date.dart';

/// Display helpers for the loan screens. Money from the lending API is baht
/// (a float with satang); dates are shown in Bangkok time, Buddhist year.

final _two = NumberFormat('#,##0.00');

/// `฿3,019.20` / `฿0.00`: instalments, interest and totals always carry two
/// decimals (FE spec "Money").
String baht2(double v) => '฿${_two.format((v.abs() * 100).round() / 100)}';

/// `3,000 บาท`: whole-baht amounts such as a principal (satang shown if any).
String bahtWords(double v) => '${formatBahtNumber(v)} บาท';

/// `฿8,000`: a whole-baht amount in a heading.
String bahtShort(double v) => formatBaht(v);

/// `15%` from basis points (`1500`), `12.5%` when it isn't whole.
String percentFromBps(int bps) {
  final v = bps / 100;
  return v == v.roundToDouble()
      ? '${v.toInt()}%'
      : '${v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}%';
}

const _bangkokOffset = Duration(hours: 7);

/// The Bangkok wall-clock time of an instant (fields read as local time).
DateTime toBangkok(DateTime instant) {
  final u = instant.toUtc().add(_bangkokOffset);
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

/// The Bangkok calendar day of an instant.
DateTime bangkokDay(DateTime instant) {
  final b = toBangkok(instant);
  return DateTime(b.year, b.month, b.day);
}

/// `08:02 น.`
String formatBangkokTime(DateTime instant) =>
    '${DateFormat('HH:mm').format(toBangkok(instant))} น.';

/// `18 พ.ย. 2569 14:32 น.`
String formatBangkokDateTime(DateTime instant) =>
    '${formatThaiDate(toBangkok(instant))} ${formatBangkokTime(instant)}';

/// `18 พ.ย. 2569` of an instant, in Bangkok.
String formatBangkokDate(DateTime instant) =>
    formatThaiDate(toBangkok(instant));

/// A date-only API field (`matures_on`, `schedule_start`, `paused_until`,
/// `deduction_date`), sent as `2026-12-19` or `2026-12-19T00:00:00Z`. The
/// calendar day is read off the string, never shifted by a time zone.
DateTime? parseApiDay(Object? v) {
  if (v == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(v.toString());
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

/// `2026-11-21` for a calendar day (push `day`, grouping keys).
String dayKey(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

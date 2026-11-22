import 'package:massdrive/core/utils/thai_date.dart';

/// Advance booking times are shown on Bangkok's clock (UTC+7, no DST)
/// whatever the phone's zone. The backend sends RFC 3339 with an offset,
/// usually UTC, sometimes with fractional seconds.

const _thaiWeekdaysShort = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

/// An RFC 3339 value from the backend, or null when absent / unreadable.
DateTime? parseAdvanceTime(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toUtc();
}

/// [t] moved to Bangkok wall-clock fields (a UTC DateTime whose
/// year/month/day/hour/minute read as Bangkok's).
DateTime toBangkok(DateTime t) => t.toUtc().add(const Duration(hours: 7));

String _two(int n) => n.toString().padLeft(2, '0');

/// "07:30 น." (Bangkok).
String formatBangkokTime(DateTime t) {
  final b = toBangkok(t);
  return '${_two(b.hour)}:${_two(b.minute)} น.';
}

/// "23 พ.ย. 07:30 น." (Bangkok), the year left out.
String formatBangkokDateTime(DateTime t) {
  final b = toBangkok(t);
  return '${b.day} ${thaiMonthsShort[b.month - 1]} '
      '${_two(b.hour)}:${_two(b.minute)} น.';
}

/// The Bangkok calendar day of [t] (time dropped), as a UTC date.
DateTime bangkokDay(DateTime t) {
  final b = toBangkok(t);
  return DateTime.utc(b.year, b.month, b.day);
}

/// "วันนี้" / "พรุ่งนี้" / "ส. 29 พ.ย." for the Bangkok day of [t], seen from
/// [now].
String formatBangkokDayLabel(DateTime t, DateTime now) {
  final day = bangkokDay(t);
  final today = bangkokDay(now);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'วันนี้';
  if (diff == 1) return 'พรุ่งนี้';
  return '${_thaiWeekdaysShort[day.weekday - 1]} ${day.day} '
      '${thaiMonthsShort[day.month - 1]}';
}

/// "พรุ่งนี้ 07:30 น." — the pickup line on a card.
String formatBangkokDayTime(DateTime t, DateTime now) =>
    '${formatBangkokDayLabel(t, now)} ${formatBangkokTime(t)}';

/// `YYYY-MM-DD` of a Bangkok day, for the board's `date` filter.
String bangkokDateParam(DateTime day) {
  final b = DateTime.utc(day.year, day.month, day.day);
  return '${b.year.toString().padLeft(4, '0')}-${_two(b.month)}-'
      '${_two(b.day)}';
}

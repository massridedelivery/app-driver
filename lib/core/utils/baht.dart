import 'package:intl/intl.dart';

final _whole = NumberFormat('#,##0');
final _satang = NumberFormat('#,##0.00');

/// `1,234` for whole baht, `0.40` when there are satang — no symbol, no sign.
/// Rounds to the satang, so a small commission isn't rounded away to "0" and
/// 82.83 isn't truncated to "82".
String formatBahtNumber(double v) {
  final cents = (v.abs() * 100).round();
  return cents % 100 == 0
      ? _whole.format(cents ~/ 100)
      : _satang.format(cents / 100);
}

/// `฿1,234` / `฿0.40`. The sign is dropped: callers that show debits pick
/// their own colour or prefix, or use [formatSignedBaht].
String formatBaht(double v) => '฿${formatBahtNumber(v)}';

/// `-฿13` for a negative amount, `+฿2` for a positive one when [plus] is set,
/// otherwise `฿2`. Anything that rounds to zero is plain `฿0` — never `฿-0`.
String formatSignedBaht(double v, {bool plus = false}) {
  final cents = (v * 100).round();
  if (cents == 0) return '฿0';
  final body = formatBaht(v);
  if (cents < 0) return '-$body';
  return plus ? '+$body' : body;
}

import 'package:intl/intl.dart';

final _whole = NumberFormat('#,##0');
final _satang = NumberFormat('#,##0.00');

/// `฿1,234` for whole baht, `฿0.40` when there are satang — so a small
/// commission isn't rounded away to "฿0".
String formatBaht(double v) {
  final cents = (v.abs() * 100).round();
  return '฿${cents % 100 == 0 ? _whole.format(cents ~/ 100) : _satang.format(cents / 100)}';
}

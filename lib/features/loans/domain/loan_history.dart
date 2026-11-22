import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

/// One Bangkok day of the statement (screen 12).
class LoanDayGroup {
  LoanDayGroup(this.day, this.events);

  final DateTime? day;
  final List<LoanEvent> events;
}

/// Groups by `deduction_date`, else the event time in Bangkok; newest day
/// first, events within a day oldest first (as the backend sends them).
List<LoanDayGroup> groupEventsByDay(List<LoanEvent> events) {
  final byKey = <String, LoanDayGroup>{};
  for (final e in events) {
    final d = e.day;
    final key = d == null ? '' : dayKey(d);
    byKey.putIfAbsent(key, () => LoanDayGroup(d, [])).events.add(e);
  }
  final groups = byKey.values.toList()
    ..sort((a, b) {
      if (a.day == null) return 1;
      if (b.day == null) return -1;
      return b.day!.compareTo(a.day!);
    });
  return groups;
}

/// How an event's amount reads (screen 12 "Signs and amounts").
class LoanEventView {
  const LoanEventView(this.symbol, this.amount, {this.positive = false});

  final String symbol;

  /// Null: no amount shown (a schedule change with amount 0).
  final String? amount;

  /// Money in (shown with "+" and colour).
  final bool positive;
}

LoanEventView eventView(LoanEvent e) {
  final a = e.amount;
  switch (e.type) {
    case LoanEventType.disbursement:
      return LoanEventView('↑', '+${baht2(a)}', positive: true);
    case LoanEventType.interestRefund:
      return LoanEventView('↑', '+${baht2(a)}', positive: true);
    case LoanEventType.deduction:
      return LoanEventView('↓', '−${baht2(a)}');
    case LoanEventType.manualPayment:
      return LoanEventView('✎', '−${baht2(a)}');
    case LoanEventType.externalPayment:
      return LoanEventView('⇄', '−${baht2(a)}');
    case LoanEventType.shortfall:
      return LoanEventView('◐', 'ขาด ${baht2(a)}');
    case LoanEventType.interestWaiver:
      return LoanEventView('✓', 'ลดดอกเบี้ย ${baht2(a)}');
    case LoanEventType.writeOff:
      return LoanEventView('■', 'ตัดหนี้สูญ ${baht2(a)}');
    case LoanEventType.pause:
      return LoanEventView('‖', a == 0 ? null : baht2(a));
    case LoanEventType.restructure:
      return LoanEventView('⇢', a == 0 ? null : baht2(a));
    case LoanEventType.consentRestored:
      return LoanEventView('↻', a == 0 ? null : baht2(a));
    default:
      return LoanEventView('•', a == 0 ? null : baht2(a));
  }
}

/// Events whose note is shown as plain text (FE spec screen 12: PAUSE,
/// RESTRUCTURE, EXTERNAL_PAYMENT). Other notes are internal (e.g. the
/// English "cooling-off: …" on a waiver) and stay hidden.
bool showsEventNote(String type) =>
    type == LoanEventType.pause ||
    type == LoanEventType.restructure ||
    type == LoanEventType.externalPayment;

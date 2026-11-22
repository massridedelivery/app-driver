import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

enum LoanNoticeKind {
  /// Paid in full: no shortfall that day.
  full,

  /// Part taken, the rest short (with the reason).
  partial,

  /// Nothing taken.
  nothing,

  /// A payment holiday covered the day.
  paused,

  /// Automatic deduction was off.
  autoOff,

  /// No events for the day yet (processing may be late).
  noData,
}

/// The morning notice for one day (screen 14), from that day's events.
class LoanNotice {
  const LoanNotice({
    required this.kind,
    this.deducted = 0,
    this.shortfall = 0,
    this.reason,
    this.interest = 0,
    this.principal = 0,
  });

  final LoanNoticeKind kind;
  final double deducted;
  final double shortfall;

  /// SHORTFALL note (NO_EARNINGS…).
  final String? reason;
  final double interest;
  final double principal;

  /// What the day asked for: taken plus short.
  double get asked => _r(deducted + shortfall);
}

double _r(double v) => (v * 100).round() / 100;

LoanNotice loanNoticeFor(LoanDetail d, DateTime day) {
  final l = d.loan;
  final events = d.eventsOn(day);
  var deducted = 0.0, short = 0.0, interest = 0.0, principal = 0.0;
  String? reason;
  for (final e in events) {
    if (e.type == LoanEventType.deduction) {
      deducted += e.amount;
      interest += e.interestComponent;
      principal += e.principalComponent;
    } else if (e.type == LoanEventType.shortfall) {
      short += e.amount;
      reason = e.note ?? reason;
    }
  }
  final hasDayEvents = deducted > 0 || short > 0;
  final revokedBy =
      l.consentRevokedAt != null &&
      !bangkokDay(l.consentRevokedAt!).isAfter(day);
  final LoanNoticeKind kind;
  if (l.isPausedOn(day) && !hasDayEvents) {
    kind = LoanNoticeKind.paused;
  } else if (revokedBy && deducted == 0) {
    kind = LoanNoticeKind.autoOff;
  } else if (!hasDayEvents) {
    kind = LoanNoticeKind.noData;
  } else if (short <= 0) {
    kind = LoanNoticeKind.full;
  } else if (deducted > 0) {
    kind = LoanNoticeKind.partial;
  } else {
    kind = LoanNoticeKind.nothing;
  }
  return LoanNotice(
    kind: kind,
    deducted: _r(deducted),
    shortfall: _r(short),
    reason: reason,
    interest: _r(interest),
    principal: _r(principal),
  );
}

import 'package:flutter/foundation.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';

/// Driver loans (สินเชื่อไรเดอร์), `/api/driver/loans…`. Shapes follow the
/// backend's `internal/lending` JSON: money is baht (float), instants are
/// RFC 3339, the calendar-day fields are Bangkok days. Every figure is the
/// server's; the app only formats it.

/// The cost statement for one amount and term (`disclosure`,
/// `sample_disclosure`).
@immutable
class LoanDisclosure {
  const LoanDisclosure({
    this.principal = 0,
    this.annualRateBps = 0,
    this.totalFees = 0,
    this.termDays = 0,
    this.deductionRateBps = 0,
    this.maxTotalInterest = 0,
    this.maxTotalRepayment = 0,
    this.coolingOffDays = 0,
    this.prepaymentPenalty = 0,
    this.dailyInstalment = 0,
    this.keepFloorThb = 0,
    this.consentVersion = '',
  });

  final double principal;
  final int annualRateBps;
  final double totalFees;
  final int termDays;
  final int deductionRateBps;

  /// Worst case within the term: nothing repaid until maturity.
  final double maxTotalInterest;
  final double maxTotalRepayment;
  final int coolingOffDays;
  final double prepaymentPenalty;
  final double dailyInstalment;

  /// The part of a day's earnings never deducted.
  final double keepFloorThb;
  final String consentVersion;

  static LoanDisclosure? maybe(Object? v) =>
      v is Map ? LoanDisclosure.fromJson(Map<String, dynamic>.from(v)) : null;

  factory LoanDisclosure.fromJson(Map<String, dynamic> j) => LoanDisclosure(
    principal: _num(j['principal']),
    annualRateBps: _int(j['annual_rate_bps']),
    totalFees: _num(j['total_fees']),
    termDays: _int(j['term_days']),
    deductionRateBps: _int(j['deduction_rate_bps']),
    maxTotalInterest: _num(j['max_total_interest']),
    maxTotalRepayment: _num(j['max_total_repayment']),
    coolingOffDays: _int(j['cooling_off_days']),
    prepaymentPenalty: _num(j['prepayment_penalty']),
    dailyInstalment: _num(j['daily_instalment']),
    keepFloorThb: _num(j['keep_floor_thb']),
    consentVersion: _str(j['consent_version']) ?? '',
  );
}

/// `GET /loans/offer`.
@immutable
class LoanOffer {
  const LoanOffer({
    required this.eligible,
    this.declineReason,
    this.maxPrincipal = 0,
    this.minPrincipal = 0,
    this.maxDailyInstalment = 0,
    this.annualRateBps = 0,
    this.deductionRateBps = 0,
    this.minTermDays = 0,
    this.maxTermDays = 0,
    this.consentVersion = '',
    this.sampleDisclosure,
    this.stepUpLimit = 0,
    this.nextStepUpLimit,
    this.paidOffLoans = 0,
  });

  final bool eligible;
  final String? declineReason;
  final double maxPrincipal;
  final double minPrincipal;
  final double maxDailyInstalment;
  final int annualRateBps;
  final int deductionRateBps;
  final int minTermDays;
  final int maxTermDays;
  final String consentVersion;
  final LoanDisclosure? sampleDisclosure;
  final double stepUpLimit;

  /// The limit after the next payoff; null when it doesn't go up.
  final double? nextStepUpLimit;
  final int paidOffLoans;

  factory LoanOffer.fromJson(Map<String, dynamic> j) => LoanOffer(
    eligible: j['eligible'] == true,
    declineReason: _str(j['decline_reason']),
    maxPrincipal: _num(j['max_principal']),
    minPrincipal: _num(j['min_principal']),
    maxDailyInstalment: _num(j['max_daily_instalment']),
    annualRateBps: _int(j['annual_rate_bps']),
    deductionRateBps: _int(j['deduction_rate_bps']),
    minTermDays: _int(j['min_term_days']),
    maxTermDays: _int(j['max_term_days']),
    consentVersion: _str(j['consent_version']) ?? '',
    sampleDisclosure: LoanDisclosure.maybe(j['sample_disclosure']),
    stepUpLimit: _num(j['step_up_limit']),
    nextStepUpLimit: j['next_step_up_limit'] == null
        ? null
        : _num(j['next_step_up_limit']),
    paidOffLoans: _int(j['paid_off_loans']),
  );
}

/// `GET /loans/eligibility` → `rules`.
@immutable
class LoanRules {
  const LoanRules({
    this.minActiveMonths = 0,
    this.minActiveDaysPerMonth = 0,
    this.minRating = 0,
    this.stepUpLimitsThb = const [],
  });

  final int minActiveMonths;
  final int minActiveDaysPerMonth;
  final double minRating;
  final List<double> stepUpLimitsThb;

  factory LoanRules.fromJson(Map<String, dynamic> j) => LoanRules(
    minActiveMonths: _int(j['min_active_months']),
    minActiveDaysPerMonth: _int(j['min_active_days_per_month']),
    minRating: _num(j['min_rating']),
    stepUpLimitsThb: [
      for (final v
          in (j['step_up_limits_thb'] is List
              ? j['step_up_limits_thb'] as List
              : const []))
        _num(v),
    ],
  );
}

/// `GET /loans/eligibility`: plain text (keep `\n`) and the rules it names.
@immutable
class LoanEligibility {
  const LoanEligibility({this.text = '', this.rules = const LoanRules()});

  final String text;
  final LoanRules rules;

  factory LoanEligibility.fromJson(Map<String, dynamic> j) => LoanEligibility(
    text: j['text']?.toString() ?? '',
    rules: j['rules'] is Map
        ? LoanRules.fromJson(Map<String, dynamic>.from(j['rules']))
        : const LoanRules(),
  );
}

/// `GET /loans/quote?principal=&term_days=`.
@immutable
class LoanQuote {
  const LoanQuote({
    required this.canApply,
    this.declineReason,
    this.problem,
    this.principal = 0,
    this.termDays = 0,
    this.minPrincipal = 0,
    this.maxPrincipal = 0,
    this.maxDailyInstalment = 0,
    this.minTermDays = 0,
    this.maxTermDays = 0,
    this.minTermDaysForAmount = 0,
    this.scheduledTotal = 0,
    this.disclosure,
    this.consentVersion = '',
  });

  final bool canApply;

  /// The driver may not borrow at all (offer codes).
  final String? declineReason;

  /// The driver may borrow, but not these figures.
  final String? problem;
  final double principal;
  final int termDays;
  final double minPrincipal;
  final double maxPrincipal;
  final double maxDailyInstalment;
  final int minTermDays;
  final int maxTermDays;

  /// Shortest affordable term for this principal; 0 = none.
  final int minTermDaysForAmount;
  final double scheduledTotal;
  final LoanDisclosure? disclosure;
  final String consentVersion;

  factory LoanQuote.fromJson(Map<String, dynamic> j) => LoanQuote(
    canApply: j['can_apply'] == true,
    declineReason: _str(j['decline_reason']),
    problem: _str(j['problem']),
    principal: _num(j['principal']),
    termDays: _int(j['term_days']),
    minPrincipal: _num(j['min_principal']),
    maxPrincipal: _num(j['max_principal']),
    maxDailyInstalment: _num(j['max_daily_instalment']),
    minTermDays: _int(j['min_term_days']),
    maxTermDays: _int(j['max_term_days']),
    minTermDaysForAmount: _int(j['min_term_days_for_amount']),
    scheduledTotal: _num(j['scheduled_total']),
    disclosure: LoanDisclosure.maybe(j['disclosure']),
    consentVersion: _str(j['consent_version']) ?? '',
  );

  /// The cost figures the driver compares (screen 4 "ใหม่" markers).
  bool sameCostAs(LoanQuote o) =>
      scheduledTotal == o.scheduledTotal &&
      disclosure?.dailyInstalment == o.disclosure?.dailyInstalment &&
      disclosure?.maxTotalInterest == o.disclosure?.maxTotalInterest &&
      disclosure?.maxTotalRepayment == o.disclosure?.maxTotalRepayment &&
      disclosure?.annualRateBps == o.disclosure?.annualRateBps;
}

/// Document kinds (`documents[].kind`).
abstract final class LoanDocKind {
  static const agreement = 'loan_agreement';
  static const deductionConsent = 'deduction_consent';
  static const privacy = 'privacy_notice';
}

/// One loan document, filled with the driver's figures.
@immutable
class LoanDocument {
  const LoanDocument({
    required this.kind,
    required this.title,
    required this.body,
    this.separate = false,
  });

  final String kind;

  /// Ask for it with its own tick box (the deduction consent).
  final bool separate;
  final String title;

  /// Markdown, shown as sent.
  final String body;

  factory LoanDocument.fromJson(Map<String, dynamic> j) => LoanDocument(
    kind: _str(j['kind']) ?? '',
    separate: j['separate'] == true,
    title: j['title']?.toString() ?? '',
    body: j['body']?.toString() ?? '',
  );
}

/// `GET /loans/terms`: send [version] and [sha256] back with the application.
@immutable
class LoanTerms {
  const LoanTerms({
    required this.version,
    required this.sha256,
    required this.documents,
  });

  final String version;
  final String sha256;
  final List<LoanDocument> documents;

  List<LoanDocument> get shared => [
    for (final d in documents)
      if (!d.separate) d,
  ];

  List<LoanDocument> get separate => [
    for (final d in documents)
      if (d.separate) d,
  ];

  /// Two separate consents are possible only when both groups exist (FE
  /// rule 2): anything else is treated as a load error.
  bool get isWellFormed =>
      version.isNotEmpty &&
      sha256.isNotEmpty &&
      shared.isNotEmpty &&
      separate.isNotEmpty;

  factory LoanTerms.fromJson(Map<String, dynamic> j) => LoanTerms(
    version: _str(j['version']) ?? '',
    sha256: _str(j['sha256']) ?? '',
    documents: [
      for (final d in (j['documents'] is List ? j['documents'] as List : []))
        if (d is Map) LoanDocument.fromJson(Map<String, dynamic>.from(d)),
    ],
  );
}

/// `GET /loans/:id/terms` and `GET /loans/applications/:id/terms`: the
/// documents exactly as accepted, filled with the amount applied for.
@immutable
class AcceptedLoanDocuments {
  const AcceptedLoanDocuments({
    required this.terms,
    this.applicationId = '',
    this.status = LoanApplicationStatus.pending,
    this.acceptedAt,
    this.principal = 0,
    this.approvedPrincipal,
    this.loanId,
  });

  final LoanTerms terms;
  final String applicationId;
  final LoanApplicationStatus status;
  final DateTime? acceptedAt;
  final double principal;
  final double? approvedPrincipal;
  final String? loanId;

  /// An admin approved less than the documents show.
  bool get approvedLower =>
      approvedPrincipal != null && approvedPrincipal! < principal;

  factory AcceptedLoanDocuments.fromJson(Map<String, dynamic> j) =>
      AcceptedLoanDocuments(
        terms: LoanTerms.fromJson(j),
        applicationId: _str(j['application_id']) ?? '',
        status: LoanApplicationStatus.parse(_str(j['status'])),
        acceptedAt: _instant(j['accepted_at']),
        principal: _num(j['principal']),
        approvedPrincipal: j['approved_principal'] == null
            ? null
            : _num(j['approved_principal']),
        loanId: _str(j['loan_id']),
      );
}

enum LoanApplicationStatus {
  pending,
  approved,
  rejected,
  declined,
  cancelled,
  unknown;

  static LoanApplicationStatus parse(String? raw) =>
      switch (raw?.toUpperCase()) {
        'PENDING' => pending,
        'APPROVED' => approved,
        'REJECTED' => rejected,
        'DECLINED' => declined,
        'CANCELLED' => cancelled,
        _ => unknown,
      };
}

/// One row of `GET /loans/applications` (newest first), also the 202 body
/// of `POST /loans`.
@immutable
class LoanApplication {
  const LoanApplication({
    required this.id,
    required this.status,
    this.principal = 0,
    this.termDays = 0,
    this.approvedPrincipal,
    this.annualRateBps = 0,
    this.dailyInstalment = 0,
    this.disclosure,
    this.declineReason,
    this.reviewNote,
    this.reviewedAt,
    this.loanId,
    this.createdAt,
  });

  final String id;
  final LoanApplicationStatus status;

  /// What the driver asked for.
  final double principal;
  final int termDays;

  /// What an admin approved (at most [principal]).
  final double? approvedPrincipal;
  final int annualRateBps;
  final double dailyInstalment;

  /// The cost statement accepted, for the amount asked for.
  final LoanDisclosure? disclosure;
  final String? declineReason;

  /// The admin's word to the driver.
  final String? reviewNote;
  final DateTime? reviewedAt;
  final String? loanId;
  final DateTime? createdAt;

  bool get approvedLower =>
      approvedPrincipal != null && approvedPrincipal! < principal;

  /// The amount that reached the driver, or the one asked for.
  double get shownPrincipal => approvedPrincipal ?? principal;

  factory LoanApplication.fromJson(Map<String, dynamic> j) => LoanApplication(
    id: _str(j['id']) ?? '',
    status: LoanApplicationStatus.parse(_str(j['status'])),
    principal: _num(j['principal']),
    termDays: _int(j['term_days']),
    approvedPrincipal: j['approved_principal'] == null
        ? null
        : _num(j['approved_principal']),
    annualRateBps: _int(j['annual_rate_bps']),
    dailyInstalment: _num(j['daily_instalment']),
    disclosure: LoanDisclosure.maybe(j['disclosure']),
    declineReason: _str(j['decline_reason']),
    reviewNote: _str(j['review_note']),
    reviewedAt: _instant(j['reviewed_at']),
    loanId: _str(j['loan_id']),
    createdAt: _instant(j['created_at']),
  );
}

enum LoanStatus {
  active,
  delinquent,
  paidOff,
  writtenOff,
  unknown;

  static LoanStatus parse(String? raw) => switch (raw?.toUpperCase()) {
    'ACTIVE' => active,
    'DELINQUENT' => delinquent,
    'PAID_OFF' => paidOff,
    'WRITTEN_OFF' => writtenOff,
    _ => unknown,
  };
}

/// A loan (`GET /loans` rows, `GET /loans/:id` → `loan`, the repay reply).
@immutable
class Loan {
  const Loan({
    required this.id,
    required this.status,
    this.principal = 0,
    this.annualRateBps = 0,
    this.termDays = 0,
    this.deductionRateBps = 0,
    this.outstandingPrincipal = 0,
    this.accruedInterest = 0,
    this.principalPaid = 0,
    this.interestPaid = 0,
    this.disclosure = const LoanDisclosure(),
    this.consentVersion = '',
    this.consentRevokedAt,
    this.disbursedAt,
    this.maturesOn,
    this.paidOffAt,
    this.createdAt,
    this.dailyInstalment = 0,
    this.scheduleStart,
    this.keepFloorThb = 0,
    this.pausedUntil,
    this.arrears = 0,
    this.daysBehind = 0,
    this.dueToday = 0,
    this.payoffAmount = 0,
    this.coolingOffUntil,
    this.interestFreePayoff = false,
    this.scheduledTotal = 0,
  });

  final String id;
  final LoanStatus status;
  final double principal;
  final int annualRateBps;
  final int termDays;
  final int deductionRateBps;
  final double outstandingPrincipal;
  final double accruedInterest;
  final double principalPaid;
  final double interestPaid;
  final LoanDisclosure disclosure;
  final String consentVersion;

  /// Set once the driver stopped automatic deduction; only the office can
  /// turn it back on.
  final DateTime? consentRevokedAt;
  final DateTime? disbursedAt;

  /// Bangkok calendar days.
  final DateTime? maturesOn;
  final DateTime? paidOffAt;
  final DateTime? createdAt;
  final double dailyInstalment;
  final DateTime? scheduleStart;
  final double keepFloorThb;
  final DateTime? pausedUntil;

  /// How far behind the schedule (as of yesterday), and that in instalments.
  final double arrears;
  final int daysBehind;

  /// What today's earnings will be asked for; 0 while paused, after a
  /// revoke, before the schedule starts and on a closed loan.
  final double dueToday;

  /// What settles the loan now (interest-free inside cooling-off).
  final double payoffAmount;

  /// When the interest-free window closes (exclusive instant).
  final DateTime? coolingOffUntil;
  final bool interestFreePayoff;
  final double scheduledTotal;

  /// "ยอดคงเหลือ": principal left plus interest accrued, the two figures
  /// shown under it (the backend's TotalDue).
  double get balance =>
      ((outstandingPrincipal + accruedInterest) * 100).round() / 100;

  double get paidTotal => ((principalPaid + interestPaid) * 100).round() / 100;

  bool get isOpen =>
      status == LoanStatus.active || status == LoanStatus.delinquent;

  /// Open, or written off (still payable; becomes PAID_OFF when paid).
  bool get acceptsPayments => isOpen || status == LoanStatus.writtenOff;

  bool get consentRevoked => consentRevokedAt != null;

  /// A payment holiday covers [today] (a Bangkok day).
  bool isPausedOn(DateTime today) =>
      pausedUntil != null && !today.isAfter(pausedUntil!);

  /// Behind on an ACTIVE loan, or past due.
  bool get isBehind =>
      status == LoanStatus.delinquent ||
      (status == LoanStatus.active && daysBehind > 0);

  static double _keepFloor(Map<String, dynamic> j, LoanDisclosure d) {
    final v = j['keep_floor_thb'];
    return v == null ? d.keepFloorThb : _num(v);
  }

  factory Loan.fromJson(Map<String, dynamic> j) {
    final disclosure =
        LoanDisclosure.maybe(j['disclosure']) ?? const LoanDisclosure();
    return Loan(
      id: _str(j['id']) ?? '',
      status: LoanStatus.parse(_str(j['status'])),
      principal: _num(j['principal']),
      annualRateBps: _int(j['annual_rate_bps']),
      termDays: _int(j['term_days']),
      deductionRateBps: _int(j['deduction_rate_bps']),
      outstandingPrincipal: _num(j['outstanding_principal']),
      accruedInterest: _num(j['accrued_interest']),
      principalPaid: _num(j['principal_paid']),
      interestPaid: _num(j['interest_paid']),
      disclosure: disclosure,
      consentVersion: _str(j['consent_version']) ?? '',
      consentRevokedAt: _instant(j['consent_revoked_at']),
      disbursedAt: _instant(j['disbursed_at']),
      maturesOn: parseApiDay(j['matures_on']),
      paidOffAt: _instant(j['paid_off_at']),
      createdAt: _instant(j['created_at']),
      dailyInstalment: _num(j['daily_instalment']),
      scheduleStart: parseApiDay(j['schedule_start']),
      keepFloorThb: _keepFloor(j, disclosure),
      pausedUntil: parseApiDay(j['paused_until']),
      arrears: _num(j['arrears']),
      daysBehind: _int(j['days_behind']),
      dueToday: _num(j['due_today']),
      payoffAmount: _num(j['payoff_amount']),
      coolingOffUntil: _instant(j['cooling_off_until']),
      interestFreePayoff: j['interest_free_payoff'] == true,
      scheduledTotal: _num(j['scheduled_total']),
    );
  }
}

/// Loan event types (`events[].type`).
abstract final class LoanEventType {
  static const disbursement = 'DISBURSEMENT';
  static const deduction = 'DEDUCTION';
  static const shortfall = 'SHORTFALL';
  static const manualPayment = 'MANUAL_PAYMENT';
  static const externalPayment = 'EXTERNAL_PAYMENT';
  static const interestWaiver = 'INTEREST_WAIVER';
  static const interestRefund = 'INTEREST_REFUND';
  static const pause = 'PAUSE';
  static const restructure = 'RESTRUCTURE';
  static const writeOff = 'WRITE_OFF';
  static const consentRestored = 'CONSENT_RESTORED';
}

/// One movement on a loan (`events[]`, oldest first).
@immutable
class LoanEvent {
  const LoanEvent({
    required this.type,
    this.id = '',
    this.amount = 0,
    this.principalComponent = 0,
    this.interestComponent = 0,
    this.deductionDate,
    this.note,
    this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final double principalComponent;
  final double interestComponent;

  /// The Bangkok day a deduction / shortfall is for.
  final DateTime? deductionDate;

  /// SHORTFALL: the rule that stopped it (NO_EARNINGS…); admin events: text.
  final String? note;
  final DateTime? createdAt;

  /// The Bangkok day it belongs to: [deductionDate], else when it happened.
  DateTime? get day =>
      deductionDate ?? (createdAt == null ? null : bangkokDay(createdAt!));

  factory LoanEvent.fromJson(Map<String, dynamic> j) => LoanEvent(
    id: _str(j['id']) ?? '',
    type: _str(j['type'])?.toUpperCase() ?? '',
    amount: _num(j['amount']),
    principalComponent: _num(j['principal_component']),
    interestComponent: _num(j['interest_component']),
    deductionDate: parseApiDay(j['deduction_date']),
    note: _str(j['note']),
    createdAt: _instant(j['created_at']),
  );
}

/// `GET /loans/:id` → `{loan, events}`.
@immutable
class LoanDetail {
  const LoanDetail({required this.loan, this.events = const []});

  final Loan loan;
  final List<LoanEvent> events;

  factory LoanDetail.fromJson(Map<String, dynamic> j) {
    // Tolerate a flat loan with `events` beside its fields.
    final raw = j['loan'] is Map ? Map<String, dynamic>.from(j['loan']) : j;
    return LoanDetail(
      loan: Loan.fromJson(raw),
      events: [
        for (final e in (j['events'] is List ? j['events'] as List : []))
          if (e is Map) LoanEvent.fromJson(Map<String, dynamic>.from(e)),
      ],
    );
  }

  /// Events for one Bangkok day, oldest first.
  List<LoanEvent> eventsOn(DateTime day) => [
    for (final e in events)
      if (e.day != null && sameDay(e.day!, day)) e,
  ];

  /// The newest SHORTFALL (its note says why the driver is behind).
  LoanEvent? get lastShortfall {
    for (final e in events.reversed) {
      if (e.type == LoanEventType.shortfall) return e;
    }
    return null;
  }

  LoanEvent? get writeOff {
    for (final e in events.reversed) {
      if (e.type == LoanEventType.writeOff) return e;
    }
    return null;
  }
}

String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

DateTime? _instant(Object? v) {
  if (v == null) return null;
  final d = DateTime.tryParse(v.toString());
  // Go's zero time ("0001-01-01T00:00:00Z") means "not set".
  if (d == null || d.year <= 1) return null;
  return d.toUtc();
}

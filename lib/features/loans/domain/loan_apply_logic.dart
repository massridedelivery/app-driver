import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

/// The decisions of the apply flow (screens 3–6), kept apart from widgets.

/// Amount chips: the minimum, 1,000, 3,000 and the maximum, inside the
/// offer's range, without repeats.
List<double> amountChoices(double min, double max) {
  final out = <double>[];
  for (final v in [min, 1000.0, 3000.0, max]) {
    if (v >= min && v <= max && v > 0 && !out.contains(v)) out.add(v);
  }
  return out;
}

/// Term chips (TermPicker): common terms clipped to the allowed range, plus
/// both bounds; never a value outside it.
List<int> termChoices(int min, int max) {
  if (min <= 0 || max < min) return const [];
  final set = <int>{min};
  for (final t in const [14, 30, 45, 60, 90, 120, 180]) {
    if (t > min && t < max) set.add(t);
  }
  set.add(max);
  final list = set.toList()..sort();
  return list;
}

/// The quote says the driver may not borrow at all (not a figures problem):
/// the screen body becomes the T1 message.
bool isQuoteDeclined(LoanQuote q) =>
    !q.canApply && q.problem == null && q.declineReason != null;

/// Lines that differ between two quotes, for the "ใหม่" markers.
Set<String> changedCostLines(LoanQuote a, LoanQuote b) => {
  if (a.disclosure?.dailyInstalment != b.disclosure?.dailyInstalment) 'daily',
  if (a.scheduledTotal != b.scheduledTotal) 'total',
  if (a.disclosure?.maxTotalInterest != b.disclosure?.maxTotalInterest)
    'interest',
};

/// The fixed statement of a separate-consent tick box (FE spec screen 5).
String separateConsentText(LoanDocument d) =>
    d.kind == LoanDocKind.deductionConsent
    ? 'ข้าพเจ้ายินยอมให้หักรายได้จากแอปเพื่อชำระสินเชื่อตาม${d.title} และทราบว่ายกเลิกการยินยอมได้ทุกเมื่อ โดยหนี้ยังคงอยู่'
    : 'ข้าพเจ้าได้อ่านและยอมรับ${d.title}';

/// What the app does after `POST /loans` is refused.
enum ApplyErrorAction {
  /// 404: lending is off.
  leave,

  /// TERMS_OUTDATED: fetch the documents again and ask again.
  termsOutdated,

  /// CONSENT_REQUIRED: back to the tick boxes.
  consentMissing,

  /// OPEN_LOAN / PENDING_APPLICATION: show "my applications".
  conflict,

  /// NOT_ELIGIBLE: the T1 message for `decline_reason`.
  declined,

  /// INVALID_REQUEST: back to the figures (the quote names the problem).
  fixFigures,

  /// No trustworthy answer: look at the applications before a re-send.
  check,

  /// Refused for another reason: nothing was created, offer a retry.
  failed,
}

ApplyErrorAction applyErrorAction(LoanApiException e) {
  if (e.lendingOff) return ApplyErrorAction.leave;
  switch (e.code) {
    case 'TERMS_OUTDATED':
      return ApplyErrorAction.termsOutdated;
    case 'CONSENT_REQUIRED':
      return ApplyErrorAction.consentMissing;
    case 'OPEN_LOAN':
    case 'PENDING_APPLICATION':
      return ApplyErrorAction.conflict;
    case 'NOT_ELIGIBLE':
      return ApplyErrorAction.declined;
    case 'INVALID_REQUEST':
      return ApplyErrorAction.fixFigures;
  }
  if (e.ambiguous) return ApplyErrorAction.check;
  if (e.statusCode == 409) return ApplyErrorAction.conflict;
  return ApplyErrorAction.failed;
}

/// After an ambiguous send: the newest application, when it is the one just
/// sent (PENDING, same figures, created within 5 minutes of [sentAt]).
LoanApplication? findSubmittedApplication(
  List<LoanApplication> apps, {
  required double principal,
  required int termDays,
  required DateTime sentAt,
}) {
  if (apps.isEmpty) return null;
  final a = apps.first;
  final created = a.createdAt;
  if (a.status != LoanApplicationStatus.pending ||
      a.principal != principal ||
      a.termDays != termDays ||
      created == null) {
    return null;
  }
  return created.isAfter(sentAt.subtract(const Duration(minutes: 5)))
      ? a
      : null;
}

/// What the app does after `POST /loans/:id/repay` is refused.
enum RepayErrorAction {
  leave,

  /// INSUFFICIENT_BALANCE: offer the `withdrawable` amount.
  insufficient,

  /// LOAN_NOT_OPEN / LOAN_CHANGED: re-read the loan.
  refresh,

  /// No trustworthy answer: re-read the loan, look for the payment.
  check,
  failed,
}

RepayErrorAction repayErrorAction(LoanApiException e) {
  if (e.lendingOff) return RepayErrorAction.leave;
  switch (e.code) {
    case 'INSUFFICIENT_BALANCE':
      return RepayErrorAction.insufficient;
    case 'LOAN_NOT_OPEN':
    case 'LOAN_CHANGED':
      return RepayErrorAction.refresh;
  }
  if (e.ambiguous) return RepayErrorAction.check;
  return RepayErrorAction.failed;
}

/// The client-side preview of a part payment (labelled "โดยประมาณ"):
/// interest settles first, then principal.
({double interest, double principal, double balanceAfter}) repayPreview(
  Loan l,
  double amount,
) {
  double r(double v) => (v * 100).round() / 100;
  final interest = r(amount < l.accruedInterest ? amount : l.accruedInterest);
  final principal = r(amount - interest);
  final after = r(l.balance - amount);
  return (
    interest: interest,
    principal: principal,
    balanceAfter: after < 0 ? 0 : after,
  );
}

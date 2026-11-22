import 'package:flutter/foundation.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';

enum LoanEntryKind {
  notEligible,
  eligible,
  waiting,
  repaying,
  behind,
  paused,
  closed,
}

/// The profile row "สินเชื่อคนขับ" (design 1H): one status line, an optional
/// chip and where a tap goes.
@immutable
class LoanEntry {
  const LoanEntry(this.kind, this.line, this.route, [this.chip]);

  final LoanEntryKind kind;
  final String line;
  final String route;
  final LoanChip? chip;

  @override
  String toString() => 'LoanEntry($kind, $line, $route, $chip)';
}

/// State precedence (FE spec screen 1, first match wins): behind (past due
/// and written off included) → paused → repaying → application waiting →
/// paid off within 7 days → eligible → not eligible. [loans] and
/// [applications] are newest first; [now] is the current instant.
LoanEntry loanEntryFor({
  required LoanOffer offer,
  required List<Loan> loans,
  required List<LoanApplication> applications,
  required DateTime now,
  LoanRules? rules,
}) {
  final today = bangkokDay(now);
  final open = [
    for (final l in loans)
      if (l.acceptsPayments) l,
  ];

  for (final l in open) {
    if (l.status == LoanStatus.writtenOff) {
      return LoanEntry(
        LoanEntryKind.behind,
        'ยอดคงเหลือ ${baht2(l.payoffAmount)}',
        LoanPaths.catchUp(l.id),
        loanChip(l, today),
      );
    }
    if (l.isBehind) {
      final due = l.dueToday > 0
          ? ' · วันนี้หักได้สูงสุด ${baht2(l.dueToday)}'
          : '';
      return LoanEntry(
        LoanEntryKind.behind,
        'ยอดค้าง ${baht2(l.arrears)}$due',
        LoanPaths.catchUp(l.id),
        loanChip(l, today),
      );
    }
  }

  for (final l in open) {
    if (l.isPausedOn(today)) {
      return LoanEntry(
        LoanEntryKind.paused,
        'ยังไม่หักจนถึง ${formatDay(l.pausedUntil!)}',
        LoanPaths.loan(l.id),
        const LoanChip('‖', 'พักชำระ', LoanTone.neutral),
      );
    }
  }

  if (open.isNotEmpty) {
    final l = open.first;
    final today2 = l.consentRevoked
        ? ' · ชำระเอง'
        : (l.dueToday > 0 ? ' · วันนี้หัก ${baht2(l.dueToday)}' : '');
    return LoanEntry(
      LoanEntryKind.repaying,
      'คงเหลือ ${baht2(l.balance)}$today2',
      LoanPaths.loan(l.id),
      loanChip(l, today),
    );
  }

  final newest = applications.isEmpty ? null : applications.first;
  if (newest != null && newest.status == LoanApplicationStatus.pending) {
    final sent = newest.createdAt == null
        ? ''
        : ' · ส่ง ${formatBangkokDate(newest.createdAt!)}';
    return LoanEntry(
      LoanEntryKind.waiting,
      'คำขอ ${bahtWords(newest.principal)}$sent',
      LoanPaths.application(newest.id),
      applicationChip(LoanApplicationStatus.pending),
    );
  }

  final last = loans.isEmpty ? null : loans.first;
  if (last != null &&
      last.status == LoanStatus.paidOff &&
      last.paidOffAt != null &&
      now.difference(last.paidOffAt!) < const Duration(days: 7)) {
    return LoanEntry(
      LoanEntryKind.closed,
      'ผ่อนครบเมื่อ ${formatBangkokDate(last.paidOffAt!)}',
      LoanPaths.loan(last.id),
      const LoanChip('✓', 'ปิดยอดแล้ว', LoanTone.success),
    );
  }

  if (offer.eligible) {
    return LoanEntry(
      LoanEntryKind.eligible,
      'กู้ได้สูงสุด ${bahtShort(offer.maxPrincipal)} · ดอกเบี้ย ${percentFromBps(offer.annualRateBps)} ต่อปี',
      LoanPaths.offer,
    );
  }

  return LoanEntry(
    LoanEntryKind.notEligible,
    loanDeclineCopy(offer.declineReason, rules: rules).heading,
    LoanPaths.offer,
    const LoanChip('⊘', 'ยังขอไม่ได้', LoanTone.neutral),
  );
}

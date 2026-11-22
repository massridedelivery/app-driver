import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

import 'loan_fixtures.dart';

void main() {
  group('LoanOffer', () {
    test('parses an eligible offer with its sample and step-up', () {
      final o = LoanOffer.fromJson(offerJson());
      expect(o.eligible, isTrue);
      expect(o.declineReason, isNull);
      expect(o.maxPrincipal, 8000);
      expect(o.minTermDays, 30);
      expect(o.maxTermDays, 180);
      expect(o.sampleDisclosure!.principal, 3000);
      expect(o.sampleDisclosure!.termDays, 30);
      expect(o.sampleDisclosure!.dailyInstalment, 100.64);
      expect(o.sampleDisclosure!.keepFloorThb, 300);
      expect(o.nextStepUpLimit, 12000);
    });

    test('next_step_up_limit null and decline_reason', () {
      final j = offerJson(eligible: false, reason: 'LENDING_CLOSED')
        ..['next_step_up_limit'] = null;
      final o = LoanOffer.fromJson(j);
      expect(o.eligible, isFalse);
      expect(o.declineReason, 'LENDING_CLOSED');
      expect(o.nextStepUpLimit, isNull);
    });
  });

  test('LoanQuote with a problem keeps min_term_days_for_amount', () {
    final q = LoanQuote.fromJson({
      'can_apply': false,
      'problem': 'INSTALMENT_TOO_HIGH',
      'principal': 8000,
      'term_days': 30,
      'max_daily_instalment': 200,
      'min_term_days_for_amount': 41,
      'scheduled_total': 8098.8,
      'disclosure': disclosureJson(principal: 8000),
    });
    expect(q.canApply, isFalse);
    expect(q.problem, 'INSTALMENT_TOO_HIGH');
    expect(q.minTermDaysForAmount, 41);
    expect(q.disclosure!.principal, 8000);
  });

  group('LoanTerms', () {
    Map<String, dynamic> doc(String kind, {bool separate = false}) => {
      'kind': kind,
      'separate': separate,
      'title': kind,
      'body': '# $kind',
    };

    test('splits shared and separate documents in API order', () {
      final t = LoanTerms.fromJson({
        'version': 'loan-terms-v3',
        'sha256': 'abc',
        'documents': [
          doc('loan_agreement'),
          doc('deduction_consent', separate: true),
          doc('privacy_notice'),
        ],
      });
      expect(t.isWellFormed, isTrue);
      expect(t.shared.map((d) => d.kind), ['loan_agreement', 'privacy_notice']);
      expect(t.separate.single.kind, 'deduction_consent');
    });

    test('without a separate document it is malformed (rule 2)', () {
      final t = LoanTerms.fromJson({
        'version': 'v',
        'sha256': 's',
        'documents': [doc('loan_agreement'), doc('privacy_notice')],
      });
      expect(t.isWellFormed, isFalse);
    });

    test('accepted documents carry the approved amount', () {
      final a = AcceptedLoanDocuments.fromJson({
        'version': 'loan-terms-v3',
        'sha256': '9f2cabcdefe41a',
        'documents': [doc('loan_agreement')],
        'application_id': 'A1',
        'status': 'APPROVED',
        'accepted_at': '2026-11-18T07:32:00Z',
        'principal': 3000,
        'approved_principal': 2000,
        'loan_id': 'L1',
      });
      expect(a.status, LoanApplicationStatus.approved);
      expect(a.approvedLower, isTrue);
      expect(a.loanId, 'L1');
      expect(formatBangkokDateTime(a.acceptedAt!), '18 พ.ย. 2569 14:32 น.');
    });
  });

  test('LoanApplication statuses and approved-lower', () {
    final a = LoanApplication.fromJson(
      applicationJson(status: 'APPROVED', approved: 2000, loanId: 'L1'),
    );
    expect(a.status, LoanApplicationStatus.approved);
    expect(a.approvedLower, isTrue);
    expect(a.shownPrincipal, 2000);
    expect(
      LoanApplicationStatus.parse('DECLINED'),
      LoanApplicationStatus.declined,
    );
    expect(LoanApplicationStatus.parse('nope'), LoanApplicationStatus.unknown);
  });

  group('Loan', () {
    test('reads the derived fields and Bangkok days', () {
      final l = Loan.fromJson(loanJson());
      expect(l.status, LoanStatus.active);
      expect(l.balance, 1905.04);
      expect(l.paidTotal, 1107.04);
      expect(l.dueToday, 100.64);
      expect(l.payoffAmount, 1905.04);
      expect(l.scheduledTotal, 3019.2);
      expect(l.maturesOn, DateTime(2026, 12, 19));
      expect(l.scheduleStart, DateTime(2026, 11, 20));
      expect(l.coolingOffUntil, DateTime.utc(2026, 11, 26, 17));
      expect(l.consentRevoked, isFalse);
      expect(l.isOpen, isTrue);
    });

    test('a date-only field is never shifted by the time zone', () {
      expect(parseApiDay('2026-12-05'), DateTime(2026, 12, 5));
      expect(parseApiDay('2026-12-05T00:00:00+07:00'), DateTime(2026, 12, 5));
      expect(parseApiDay(null), isNull);
    });

    test('paused, behind, written off', () {
      final paused = Loan.fromJson(
        loanJson(pausedUntil: '2026-12-05T00:00:00Z'),
      );
      expect(paused.isPausedOn(DateTime(2026, 12, 5)), isTrue);
      expect(paused.isPausedOn(DateTime(2026, 12, 6)), isFalse);
      expect(Loan.fromJson(loanJson(daysBehind: 2)).isBehind, isTrue);
      expect(Loan.fromJson(loanJson(status: 'DELINQUENT')).isBehind, isTrue);
      final w = Loan.fromJson(loanJson(status: 'WRITTEN_OFF'));
      expect(w.isOpen, isFalse);
      expect(w.acceptsPayments, isTrue);
    });

    test('Go zero time means not set', () {
      final j = loanJson()..['cooling_off_until'] = '0001-01-01T00:00:00Z';
      expect(Loan.fromJson(j).coolingOffUntil, isNull);
    });
  });

  test('LoanDetail reads {loan, events} and finds the last shortfall', () {
    final d = LoanDetail.fromJson({
      'loan': loanJson(),
      'events': [
        {
          'type': 'DISBURSEMENT',
          'amount': 3000,
          'created_at': '2026-11-19T07:20:00Z',
        },
        {
          'type': 'DEDUCTION',
          'amount': 60,
          'principal_component': 59.13,
          'interest_component': 0.87,
          'deduction_date': '2026-11-28T00:00:00Z',
          'created_at': '2026-11-28T16:00:00Z',
        },
        {
          'type': 'SHORTFALL',
          'amount': 40.64,
          'deduction_date': '2026-11-28T00:00:00Z',
          'note': 'KEEP_FLOOR',
          'created_at': '2026-11-28T16:00:00Z',
        },
      ],
    });
    expect(d.loan.id, 'L1');
    expect(d.events, hasLength(3));
    expect(d.lastShortfall!.note, 'KEEP_FLOOR');
    expect(d.eventsOn(DateTime(2026, 11, 28)), hasLength(2));
    // The disbursement has no deduction_date: its Bangkok day.
    expect(d.events.first.day, DateTime(2026, 11, 19));
  });

  group('format', () {
    test('money', () {
      expect(baht2(3019.2), '฿3,019.20');
      expect(baht2(0), '฿0.00');
      expect(bahtWords(3000), '3,000 บาท');
      expect(percentFromBps(1500), '15%');
      expect(percentFromBps(1250), '12.5%');
    });

    test('Bangkok time', () {
      expect(
        formatBangkokDateTime(DateTime.utc(2026, 11, 30, 17, 5)),
        '1 ธ.ค. 2569 00:05 น.',
      );
      expect(
        bangkokDay(DateTime.utc(2026, 11, 30, 17, 5)),
        DateTime(2026, 12, 1),
      );
    });
  });
}

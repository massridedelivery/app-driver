import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

import 'loan_fixtures.dart';

void main() {
  group('decline lines (T1 + backend contract)', () {
    test('contract wording for the new codes', () {
      expect(
        loanDeclineCopy('LENDING_CLOSED').heading,
        'ขณะนี้ยังไม่เปิดให้ขอสินเชื่อ',
      );
      expect(
        loanDeclineCopy('NOT_IN_PILOT').heading,
        'ยังไม่เปิดให้บัญชีของคุณขอสินเชื่อ',
      );
      expect(
        loanDeclineCopy('INSUFFICIENT_HISTORY').heading,
        'ประวัติการวิ่งงานยังไม่พอ',
      );
    });

    test('INACTIVE_MONTHS names rules.min_active_months', () {
      const rules = LoanRules(minActiveMonths: 3);
      expect(
        loanDeclineCopy('INACTIVE_MONTHS', rules: rules).heading,
        'ต้องวิ่งงานต่อเนื่องอย่างน้อย 3 เดือน',
      );
      // Rules not loaded: no invented number.
      expect(
        loanDeclineCopy('INACTIVE_MONTHS').heading,
        'ต้องวิ่งงานต่อเนื่องตามเกณฑ์',
      );
    });

    test('LOW_RATING names rules.min_rating', () {
      const rules = LoanRules(minRating: 4.5);
      expect(loanDeclineCopy('LOW_RATING', rules: rules).hint, contains('4.5'));
    });

    test('actions', () {
      expect(
        loanDeclineCopy('PLATFORM_DEBT').action,
        LoanDeclineAction.settleDebt,
      );
      expect(
        loanDeclineCopy('NOT_VERIFIED').action,
        LoanDeclineAction.documents,
      );
      expect(
        loanDeclineCopy('PROFILE_INCOMPLETE').action,
        LoanDeclineAction.editProfile,
      );
      expect(
        loanDeclineCopy('NO_PAYOUT_ACCOUNT').action,
        LoanDeclineAction.payoutAccount,
      );
      expect(loanDeclineCopy('OPEN_LOAN').action, LoanDeclineAction.viewLoan);
      expect(
        loanDeclineCopy('PENDING_APPLICATION').action,
        LoanDeclineAction.viewApplication,
      );
      for (final c in [
        'DELINQUENT_HISTORY',
        'AGE_OUT_OF_RANGE',
        'ACCOUNT_INACTIVE',
        'ADMIN_LIMIT',
      ]) {
        expect(loanDeclineCopy(c).action, LoanDeclineAction.support, reason: c);
      }
      expect(loanDeclineCopy('LENDING_CLOSED').action, LoanDeclineAction.none);
    });

    test('every contract code has Thai copy, never the raw code', () {
      const codes = [
        'LENDING_CLOSED',
        'NOT_IN_PILOT',
        'INACTIVE_MONTHS',
        'INSUFFICIENT_HISTORY',
        'OPEN_LOAN',
        'PENDING_APPLICATION',
        'DELINQUENT_HISTORY',
        'PLATFORM_DEBT',
        'LOW_EARNINGS',
        'LOW_RATING',
        'MOSTLY_CASH',
        'NOT_VERIFIED',
        'PROFILE_INCOMPLETE',
        'AGE_OUT_OF_RANGE',
        'NO_PAYOUT_ACCOUNT',
        'ACCOUNT_INACTIVE',
        'ADMIN_LIMIT',
      ];
      final fallback = loanDeclineCopy('SOMETHING_NEW').heading;
      for (final c in codes) {
        final copy = loanDeclineCopy(c);
        expect(copy.heading, isNot(contains(c)));
        expect(copy.heading, isNot(fallback), reason: c);
      }
      expect(fallback, 'ขณะนี้ยังขอสินเชื่อไม่ได้');
      expect(loanDeclineCopy(null).heading, fallback);
    });
  });

  group('problem lines (T2)', () {
    LoanQuote q(String problem, {int minTermForAmount = 0}) => LoanQuote(
      canApply: false,
      problem: problem,
      minPrincipal: 500,
      maxPrincipal: 8000,
      maxDailyInstalment: 200,
      minTermDays: 30,
      maxTermDays: 180,
      minTermDaysForAmount: minTermForAmount,
    );

    test('INSTALMENT_TOO_HIGH offers "ใช้ N วัน"', () {
      final c = loanProblemCopy(
        q('INSTALMENT_TOO_HIGH', minTermForAmount: 41),
        principal: 8000,
        termDays: 30,
      )!;
      expect(c.line, 'ผ่อนต่อวันเกิน ฿200.00 · เลือกอย่างน้อย 41 วัน');
      expect(c.fixLabel, 'ใช้ 41 วัน');
      expect(c.fixTermDays, 41);
    });

    test('INSTALMENT_TOO_HIGH at no term: no fix button', () {
      final c = loanProblemCopy(
        q('INSTALMENT_TOO_HIGH'),
        principal: 80000,
        termDays: 30,
      )!;
      expect(c.fixLabel, isNull);
    });

    test('amount bounds and the nearest term bound', () {
      expect(
        loanProblemCopy(
          q('AMOUNT_TOO_LOW'),
          principal: 100,
          termDays: 30,
        )!.fixPrincipal,
        500,
      );
      expect(
        loanProblemCopy(
          q('AMOUNT_ABOVE_LIMIT'),
          principal: 9000,
          termDays: 30,
        )!.fixLabel,
        'ใช้ 8,000 บาท',
      );
      expect(
        loanProblemCopy(
          q('TERM_OUT_OF_RANGE'),
          principal: 3000,
          termDays: 10,
        )!.fixTermDays,
        30,
      );
      expect(
        loanProblemCopy(
          q('TERM_OUT_OF_RANGE'),
          principal: 3000,
          termDays: 200,
        )!.fixTermDays,
        180,
      );
    });

    test('no problem: nothing', () {
      expect(
        loanProblemCopy(
          const LoanQuote(canApply: true),
          principal: 1,
          termDays: 1,
        ),
        isNull,
      );
    });
  });

  test('event labels (T5) incl. INTEREST_REFUND and CONSENT_RESTORED', () {
    expect(loanEventLabel('DISBURSEMENT'), 'โอนเงินกู้');
    expect(loanEventLabel('DEDUCTION'), 'หักจากรายได้');
    expect(loanEventLabel('SHORTFALL'), 'หักไม่ครบ');
    expect(loanEventLabel('MANUAL_PAYMENT'), 'จ่ายเอง');
    expect(loanEventLabel('EXTERNAL_PAYMENT'), 'จ่ายนอกระบบ');
    expect(loanEventLabel('INTEREST_WAIVER'), 'ยกเว้นดอกเบี้ย');
    expect(loanEventLabel('INTEREST_REFUND'), 'คืนดอกเบี้ย');
    expect(loanEventLabel('PAUSE'), 'พักชำระ');
    expect(loanEventLabel('RESTRUCTURE'), 'ขยายระยะผ่อน');
    expect(loanEventLabel('WRITE_OFF'), 'ตัดหนี้สูญ');
    expect(loanEventLabel('CONSENT_RESTORED'), 'เปิดหักอัตโนมัติอีกครั้ง');
  });

  test('shortfall notes (T3)', () {
    expect(loanShortfallLabel('NO_EARNINGS'), 'ไม่มีรายได้ผ่านแอป');
    expect(loanShortfallLabel('KEEP_FLOOR'), 'รายได้เกินยอดที่เว้นไว้ไม่พอ');
    expect(loanShortfallLabel('DEDUCTION_CAP'), 'ติดเพดานการหักต่อวัน');
    expect(loanShortfallLabel('WALLET'), 'ยอดถอนได้ไม่พอ');
    expect(loanShortfallLabel(null), 'หักไม่ครบ');
    expect(
      loanShortfallExplain('KEEP_FLOOR', keepFloor: 300),
      contains('300 บาท'),
    );
    expect(
      loanShortfallExplain('DEDUCTION_CAP', deductionRateBps: 3000),
      contains('30%'),
    );
  });

  group('chips (T4)', () {
    final today = DateTime(2026, 12, 1);
    test('loan', () {
      expect(loanChip(Loan.fromJson(loanJson()), today).label, 'กำลังผ่อน');
      expect(
        loanChip(Loan.fromJson(loanJson(daysBehind: 2)), today).label,
        'ค้าง 2 วัน',
      );
      expect(
        loanChip(Loan.fromJson(loanJson(status: 'DELINQUENT')), today).label,
        'เลยกำหนดชำระ',
      );
      expect(
        loanChip(Loan.fromJson(loanJson(status: 'WRITTEN_OFF')), today).label,
        'ตัดหนี้สูญ',
      );
      expect(
        loanChip(Loan.fromJson(loanJson(status: 'PAID_OFF')), today).label,
        'ปิดยอดแล้ว',
      );
      expect(
        loanChip(
          Loan.fromJson(loanJson(pausedUntil: '2026-12-05')),
          today,
        ).label,
        'พักชำระถึง 5 ธ.ค. 2569',
      );
      expect(
        loanChip(
          Loan.fromJson(loanJson(consentRevokedAt: '2026-12-01T02:15:00Z')),
          today,
        ).label,
        'หักอัตโนมัติปิดอยู่',
      );
    });

    test('application: icon + word', () {
      expect(
        applicationChip(LoanApplicationStatus.pending).toString(),
        '◷ รอพิจารณา',
      );
      expect(
        applicationChip(LoanApplicationStatus.rejected).toString(),
        '✕ ไม่อนุมัติ',
      );
      expect(
        applicationChip(LoanApplicationStatus.declined).toString(),
        '⊘ ไม่ผ่านเกณฑ์',
      );
      expect(
        applicationChip(LoanApplicationStatus.cancelled).toString(),
        '↩ ยกเลิกแล้ว',
      );
    });
  });

  test('cooling-off wording and end time (Bangkok, the minute before)', () {
    expect(coolingOffLine(7), 'คืนเงินต้นครบภายใน 7 วัน ไม่เสียดอกเบี้ยเลย');
    // cooling_off_until = 27 Nov 00:00 Bangkok.
    expect(
      coolingOffUntilText(DateTime.utc(2026, 11, 26, 17)),
      'ถึง 26 พ.ย. 2569 23:59 น.',
    );
  });
}

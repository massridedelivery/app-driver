import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/loans/domain/loan_entry.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

import 'loan_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 12, 1, 3); // 1 Dec 10:00 Bangkok
  final eligible = LoanOffer.fromJson(offerJson());
  final closed = LoanOffer.fromJson(
    offerJson(eligible: false, reason: 'LENDING_CLOSED'),
  );

  LoanEntry entry({
    LoanOffer? offer,
    List<Map<String, dynamic>> loans = const [],
    List<Map<String, dynamic>> apps = const [],
  }) => loanEntryFor(
    offer: offer ?? eligible,
    loans: [for (final l in loans) Loan.fromJson(l)],
    applications: [for (final a in apps) LoanApplication.fromJson(a)],
    now: now,
  );

  test('eligible, no history', () {
    final e = entry();
    expect(e.kind, LoanEntryKind.eligible);
    expect(e.line, 'กู้ได้สูงสุด ฿8,000 · ดอกเบี้ย 15% ต่อปี');
    expect(e.chip, isNull);
    expect(e.route, '/loans');
  });

  test('not eligible shows the Thai line, never the code', () {
    final e = entry(offer: closed);
    expect(e.kind, LoanEntryKind.notEligible);
    expect(e.line, 'ขณะนี้ยังไม่เปิดให้ขอสินเชื่อ');
    expect(e.chip!.label, 'ยังขอไม่ได้');
  });

  test('waiting application', () {
    final e = entry(apps: [applicationJson()]);
    expect(e.kind, LoanEntryKind.waiting);
    expect(e.line, 'คำขอ 3,000 บาท · ส่ง 18 พ.ย. 2569');
    expect(e.route, '/loans/applications/A1');
  });

  test('repaying beats a waiting application; LENDING_CLOSED keeps it', () {
    final e = entry(
      offer: closed,
      loans: [loanJson()],
      apps: [applicationJson()],
    );
    expect(e.kind, LoanEntryKind.repaying);
    expect(e.line, 'คงเหลือ ฿1,905.04 · วันนี้หัก ฿100.64');
    expect(e.route, '/loans/loan/L1');
  });

  test('repaying with auto-deduction off', () {
    final e = entry(
      loans: [loanJson(consentRevokedAt: '2026-11-30T02:00:00Z', dueToday: 0)],
    );
    expect(e.line, 'คงเหลือ ฿1,905.04 · ชำระเอง');
    expect(e.chip!.label, 'หักอัตโนมัติปิดอยู่');
  });

  test('behind beats paused and repaying, opens the catch-up card', () {
    final e = entry(
      loans: [loanJson(daysBehind: 2, arrears: 201.28, dueToday: 201.28)],
    );
    expect(e.kind, LoanEntryKind.behind);
    expect(e.line, 'ยอดค้าง ฿201.28 · วันนี้หักได้สูงสุด ฿201.28');
    expect(e.chip!.label, 'ค้าง 2 วัน');
    expect(e.route, '/loans/loan/L1/catch-up');
  });

  test('written off shows as behind with the balance', () {
    final e = entry(loans: [loanJson(status: 'WRITTEN_OFF')]);
    expect(e.kind, LoanEntryKind.behind);
    expect(e.line, 'ยอดคงเหลือ ฿1,905.04');
    expect(e.chip!.label, 'ตัดหนี้สูญ');
  });

  test('paused', () {
    final e = entry(loans: [loanJson(pausedUntil: '2026-12-05', dueToday: 0)]);
    expect(e.kind, LoanEntryKind.paused);
    expect(e.line, 'ยังไม่หักจนถึง 5 ธ.ค. 2569');
  });

  test('paid off within 7 days, then back to the offer', () {
    final recent = entry(
      loans: [loanJson(status: 'PAID_OFF', paidOffAt: '2026-11-28T23:00:00Z')],
    );
    expect(recent.kind, LoanEntryKind.closed);
    expect(recent.line, 'ผ่อนครบเมื่อ 29 พ.ย. 2569');
    final old = entry(
      loans: [loanJson(status: 'PAID_OFF', paidOffAt: '2026-11-20T00:00:00Z')],
    );
    expect(old.kind, LoanEntryKind.eligible);
  });
}

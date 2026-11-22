import 'package:flutter/foundation.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

/// The app's Thai copy for the codes the lending API sends (FE spec §T).
/// The API never sends Thai; the raw code is never shown.

/// What a T1 decline lets the driver do next.
enum LoanDeclineAction {
  none,
  viewLoan,
  viewApplication,
  settleDebt,
  documents,
  editProfile,
  payoutAccount,
  support;

  String? get label => switch (this) {
    none => null,
    viewLoan => 'ดูสินเชื่อของฉัน',
    viewApplication => 'ดูคำขอ',
    settleDebt => 'ไปชำระยอดค้าง',
    documents => 'ไปที่เอกสาร',
    editProfile => 'แก้ไขโปรไฟล์',
    payoutAccount => 'เพิ่มบัญชีรับเงิน',
    support => 'ติดต่อฝ่ายช่วยเหลือ',
  };
}

/// T1: why the driver can't borrow, what they can do, and a button.
@immutable
class LoanDeclineCopy {
  const LoanDeclineCopy(
    this.heading,
    this.hint, [
    this.action = LoanDeclineAction.none,
  ]);

  /// The short line (also the profile row's second line).
  final String heading;
  final String hint;
  final LoanDeclineAction action;
}

/// The Thai line for an offer / quote / apply `decline_reason`. [rules]
/// fills the figures some lines name (from `GET /loans/eligibility`).
LoanDeclineCopy loanDeclineCopy(String? code, {LoanRules? rules}) {
  switch (code) {
    case 'LENDING_CLOSED':
      return const LoanDeclineCopy(
        'ขณะนี้ยังไม่เปิดให้ขอสินเชื่อ',
        'สินเชื่อที่ผ่อนอยู่ยังดำเนินต่อตามปกติ กลับมาตรวจสอบอีกครั้งภายหลัง',
      );
    case 'NOT_IN_PILOT':
      return const LoanDeclineCopy(
        'ยังไม่เปิดให้บัญชีของคุณขอสินเชื่อ',
        'เรากำลังทยอยเปิดให้คนขับ เมื่อเปิดให้คุณแล้วจะแจ้งในแอป',
      );
    case 'INACTIVE_MONTHS':
      final n = rules?.minActiveMonths ?? 0;
      return LoanDeclineCopy(
        n > 0
            ? 'ต้องวิ่งงานต่อเนื่องอย่างน้อย $n เดือน'
            : 'ต้องวิ่งงานต่อเนื่องตามเกณฑ์',
        'รับงานต่อเนื่องทุกเดือน แล้วกลับมาตรวจสอบอีกครั้ง',
      );
    case 'INSUFFICIENT_HISTORY':
      return const LoanDeclineCopy(
        'ประวัติการวิ่งงานยังไม่พอ',
        'รับงานต่อเนื่องสม่ำเสมอ แล้วกลับมาตรวจสอบอีกครั้ง',
      );
    case 'OPEN_LOAN':
      return const LoanDeclineCopy(
        'คุณมีสินเชื่อที่กำลังผ่อนอยู่',
        'ปิดยอดเดิมให้ครบก่อน แล้วจึงขอใหม่ได้',
        LoanDeclineAction.viewLoan,
      );
    case 'PENDING_APPLICATION':
      return const LoanDeclineCopy(
        'คุณมีคำขอที่รอพิจารณาอยู่',
        'รอผลจากเจ้าหน้าที่ หรือยกเลิกคำขอเดิมก่อนยื่นใหม่',
        LoanDeclineAction.viewApplication,
      );
    case 'DELINQUENT_HISTORY':
      return const LoanDeclineCopy(
        'เคยมีสินเชื่อที่ชำระไม่ครบตามกำหนด',
        'หากคิดว่าข้อมูลไม่ถูกต้อง ติดต่อฝ่ายช่วยเหลือ',
        LoanDeclineAction.support,
      );
    case 'PLATFORM_DEBT':
      return const LoanDeclineCopy(
        'คุณมียอดค้างกับแพลตฟอร์มเกิน ฿500',
        'ชำระยอดค้างให้เหลือไม่เกิน ฿500 แล้วลองอีกครั้ง',
        LoanDeclineAction.settleDebt,
      );
    case 'LOW_EARNINGS':
      return const LoanDeclineCopy(
        'รายได้ผ่านแอปช่วงที่ผ่านมายังไม่ถึงเกณฑ์',
        'รับงานต่อเนื่องสม่ำเสมอ แล้วกลับมาตรวจสอบอีกครั้ง',
      );
    case 'LOW_RATING':
      final r = rules?.minRating ?? 0;
      return LoanDeclineCopy(
        'คะแนนจากลูกค้ายังไม่ถึงเกณฑ์',
        r > 0
            ? 'ต้องมีคะแนนอย่างน้อย ${_trim(r)} รักษาคะแนนให้สูงขึ้น แล้วกลับมาตรวจสอบอีกครั้ง'
            : 'รักษาคะแนนให้สูงขึ้น แล้วกลับมาตรวจสอบอีกครั้ง',
      );
    case 'MOSTLY_CASH':
      return const LoanDeclineCopy(
        'งานส่วนใหญ่ของคุณรับเป็นเงินสด',
        'สินเชื่อนี้ผ่อนจากรายได้ในแอป ต้องมีงานที่จ่ายผ่านแอปอย่างน้อยครึ่งหนึ่งของงานทั้งหมด',
      );
    case 'NOT_VERIFIED':
      return const LoanDeclineCopy(
        'บัญชียังยืนยันตัวตนไม่ครบ',
        'ส่งเอกสารให้ครบและรอการตรวจสอบ',
        LoanDeclineAction.documents,
      );
    case 'PROFILE_INCOMPLETE':
      return const LoanDeclineCopy(
        'ยังไม่มีวันเกิดในโปรไฟล์',
        'เพิ่มวันเกิด แล้วกลับมาตรวจสอบอีกครั้ง',
        LoanDeclineAction.editProfile,
      );
    case 'AGE_OUT_OF_RANGE':
      return const LoanDeclineCopy(
        'สินเชื่อนี้สำหรับผู้มีอายุ 20–65 ปี',
        'หากวันเกิดในโปรไฟล์ไม่ถูกต้อง ติดต่อฝ่ายช่วยเหลือ',
        LoanDeclineAction.support,
      );
    case 'NO_PAYOUT_ACCOUNT':
      return const LoanDeclineCopy(
        'ยังไม่มีบัญชีรับเงิน',
        'เพิ่มบัญชีธนาคารสำหรับถอนเงินก่อน',
        LoanDeclineAction.payoutAccount,
      );
    case 'ACCOUNT_INACTIVE':
      return const LoanDeclineCopy(
        'บัญชีของคุณไม่ได้อยู่ในสถานะใช้งาน',
        'ติดต่อฝ่ายช่วยเหลือเพื่อตรวจสอบบัญชี',
        LoanDeclineAction.support,
      );
    case 'ADMIN_LIMIT':
      return const LoanDeclineCopy(
        'ขณะนี้บัญชีของคุณยังขอสินเชื่อไม่ได้',
        'ติดต่อฝ่ายช่วยเหลือหากต้องการทราบรายละเอียด',
        LoanDeclineAction.support,
      );
    default:
      return const LoanDeclineCopy(
        'ขณะนี้ยังขอสินเชื่อไม่ได้',
        'ลองใหม่ภายหลัง หรือติดต่อฝ่ายช่วยเหลือ',
        LoanDeclineAction.support,
      );
  }
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// T2: a quote `problem` — the line under the input and the one-tap fix.
@immutable
class LoanProblemCopy {
  const LoanProblemCopy(
    this.line, {
    this.fixLabel,
    this.fixPrincipal,
    this.fixTermDays,
  });

  final String line;
  final String? fixLabel;

  /// Set the amount to this (whole baht).
  final double? fixPrincipal;

  /// Set the term to this.
  final int? fixTermDays;
}

/// [principal] / [termDays] are what the driver entered.
LoanProblemCopy? loanProblemCopy(
  LoanQuote q, {
  required double principal,
  required int termDays,
}) {
  switch (q.problem) {
    case 'AMOUNT_TOO_LOW':
      return LoanProblemCopy(
        'กู้ได้ขั้นต่ำ ${bahtWords(q.minPrincipal)}',
        fixLabel: 'ใช้ ${bahtWords(q.minPrincipal)}',
        fixPrincipal: q.minPrincipal,
      );
    case 'AMOUNT_ABOVE_LIMIT':
      return LoanProblemCopy(
        'กู้ได้สูงสุด ${bahtWords(q.maxPrincipal)}',
        fixLabel: 'ใช้ ${bahtWords(q.maxPrincipal)}',
        fixPrincipal: q.maxPrincipal,
      );
    case 'TERM_OUT_OF_RANGE':
      final nearest = termDays < q.minTermDays ? q.minTermDays : q.maxTermDays;
      return LoanProblemCopy(
        'เลือกได้ ${q.minTermDays}–${q.maxTermDays} วัน',
        fixLabel: 'ใช้ $nearest วัน',
        fixTermDays: nearest,
      );
    case 'INSTALMENT_TOO_HIGH':
      final n = q.minTermDaysForAmount;
      if (n <= 0) {
        // No term makes this amount affordable: lower the amount instead.
        return LoanProblemCopy(
          'ผ่อนต่อวันเกิน ${baht2(q.maxDailyInstalment)} ลองลดยอดกู้',
        );
      }
      return LoanProblemCopy(
        'ผ่อนต่อวันเกิน ${baht2(q.maxDailyInstalment)} · เลือกอย่างน้อย $n วัน',
        fixLabel: 'ใช้ $n วัน',
        fixTermDays: n,
      );
    case null:
      return null;
    default:
      return const LoanProblemCopy('ปรับยอดหรือจำนวนวัน แล้วลองอีกครั้ง');
  }
}

/// T5: `events[].type`.
String loanEventLabel(String type) => switch (type) {
  LoanEventType.disbursement => 'โอนเงินกู้',
  LoanEventType.deduction => 'หักจากรายได้',
  LoanEventType.shortfall => 'หักไม่ครบ',
  LoanEventType.manualPayment => 'จ่ายเอง',
  LoanEventType.externalPayment => 'จ่ายนอกระบบ',
  LoanEventType.interestWaiver => 'ยกเว้นดอกเบี้ย',
  LoanEventType.interestRefund => 'คืนดอกเบี้ย',
  LoanEventType.pause => 'พักชำระ',
  LoanEventType.restructure => 'ขยายระยะผ่อน',
  LoanEventType.writeOff => 'ตัดหนี้สูญ',
  LoanEventType.consentRestored => 'เปิดหักอัตโนมัติอีกครั้ง',
  _ => 'รายการอื่น',
};

/// T3: the short SHORTFALL reason (`note`).
String loanShortfallLabel(String? note) => switch (note) {
  'NO_EARNINGS' => 'ไม่มีรายได้ผ่านแอป',
  'KEEP_FLOOR' => 'รายได้เกินยอดที่เว้นไว้ไม่พอ',
  'DEDUCTION_CAP' => 'ติดเพดานการหักต่อวัน',
  'WALLET' => 'ยอดถอนได้ไม่พอ',
  _ => 'หักไม่ครบ',
};

/// T3: the plain-Thai explanation, with the loan's own floor and cap.
String loanShortfallExplain(
  String? note, {
  double keepFloor = 0,
  int deductionRateBps = 0,
}) {
  final floor = keepFloor > 0 ? bahtWords(keepFloor) : 'ส่วนแรก';
  final cap = deductionRateBps > 0
      ? percentFromBps(deductionRateBps)
      : 'ส่วนที่ตกลงไว้';
  return switch (note) {
    'NO_EARNINGS' =>
      'วันนั้นไม่มีรายได้ผ่านแอป จึงยังไม่ได้หัก ยอดนี้จะหักจากวันที่มีรายได้',
    'KEEP_FLOOR' =>
      'เราเว้นรายได้ $floor ของทุกวันไว้ให้คุณเสมอ วันนั้นรายได้ส่วนที่เกินไม่พอสำหรับค่างวด',
    'DEDUCTION_CAP' =>
      'หักได้ไม่เกิน $cap ของรายได้ในวันนั้น ส่วนที่เหลือจะหักในวันถัดไป',
    'WALLET' =>
      'ยอดที่ถอนได้ในกระเป๋าเงินไม่พอ (เช่น ถอนออกไปแล้ว) ส่วนที่ขาดยังค้างอยู่',
    _ => 'ยอดที่ขาดยังค้างอยู่ และจะหักในวันถัดไป',
  };
}

/// How a status chip reads (icon + word, never colour alone).
enum LoanTone { neutral, info, success, warning }

@immutable
class LoanChip {
  const LoanChip(this.symbol, this.label, this.tone);

  /// A text glyph (◷ ✓ ✕ ⊘ ↩ ↻ ! ★ ■ ‖ ⦸).
  final String symbol;
  final String label;
  final LoanTone tone;

  @override
  bool operator ==(Object other) =>
      other is LoanChip &&
      other.symbol == symbol &&
      other.label == label &&
      other.tone == tone;

  @override
  int get hashCode => Object.hash(symbol, label, tone);

  @override
  String toString() => '$symbol $label';
}

/// T4 for applications.
LoanChip applicationChip(LoanApplicationStatus s) => switch (s) {
  LoanApplicationStatus.pending => const LoanChip(
    '◷',
    'รอพิจารณา',
    LoanTone.neutral,
  ),
  LoanApplicationStatus.approved => const LoanChip(
    '✓',
    'อนุมัติแล้ว',
    LoanTone.success,
  ),
  LoanApplicationStatus.rejected => const LoanChip(
    '✕',
    'ไม่อนุมัติ',
    LoanTone.neutral,
  ),
  LoanApplicationStatus.declined => const LoanChip(
    '⊘',
    'ไม่ผ่านเกณฑ์',
    LoanTone.neutral,
  ),
  LoanApplicationStatus.cancelled => const LoanChip(
    '↩',
    'ยกเลิกแล้ว',
    LoanTone.neutral,
  ),
  LoanApplicationStatus.unknown => const LoanChip(
    '•',
    'ไม่ทราบสถานะ',
    LoanTone.neutral,
  ),
};

/// T4 for a loan, derived states first: written off, past due, behind,
/// paused, auto-deduction off, then the status. [today] is a Bangkok day.
LoanChip loanChip(Loan l, DateTime today) {
  switch (l.status) {
    case LoanStatus.paidOff:
      return const LoanChip('★', 'ปิดยอดแล้ว', LoanTone.success);
    case LoanStatus.writtenOff:
      return const LoanChip('■', 'ตัดหนี้สูญ', LoanTone.neutral);
    case LoanStatus.delinquent:
      return const LoanChip('!', 'เลยกำหนดชำระ', LoanTone.warning);
    case LoanStatus.active:
    case LoanStatus.unknown:
      if (l.daysBehind > 0) {
        return LoanChip('!', 'ค้าง ${l.daysBehind} วัน', LoanTone.warning);
      }
      if (l.isPausedOn(today)) {
        return LoanChip(
          '‖',
          'พักชำระถึง ${_thaiDay(l.pausedUntil!)}',
          LoanTone.neutral,
        );
      }
      if (l.consentRevoked) {
        return const LoanChip('⦸', 'หักอัตโนมัติปิดอยู่', LoanTone.neutral);
      }
      return const LoanChip('↻', 'กำลังผ่อน', LoanTone.info);
  }
}

String _thaiDay(DateTime d) => formatDay(d);

/// `20 พ.ย. 2569` for a calendar day (no time-zone shift).
String formatDay(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year + 543}';

const _months = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

/// The cooling-off line: "คืนเงินต้นครบภายใน 7 วัน ไม่เสียดอกเบี้ยเลย".
String coolingOffLine(int days) =>
    'คืนเงินต้นครบภายใน ${days > 0 ? days : 7} วัน ไม่เสียดอกเบี้ยเลย';

/// The end of the interest-free window for display. `cooling_off_until` is
/// the first instant after it (Bangkok midnight), so the last minute before
/// it is shown: "ถึง 26 พ.ย. 2569 23:59 น.".
String coolingOffUntilText(DateTime until) =>
    'ถึง ${formatBangkokDateTime(until.subtract(const Duration(minutes: 1)))}';

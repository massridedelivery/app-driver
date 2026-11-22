import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_markdown.dart';

void main() {
  test('parses headings, clause lines, lists and nesting', () {
    const md = '''
# สัญญากู้ยืมเงิน

สัญญานี้ทำขึ้นระหว่าง **ผู้ให้กู้** กับผู้กู้

## ข้อ 1 จำนวนเงินกู้
1.1 ผู้กู้ขอกู้เงิน **3,000 บาท**
1.2 สัญญามีผลเมื่อโอนเงิน

1. **ยอดที่หักต่อวัน:** วันละ 100.64 บาท
2. **เพดานการหัก:**
   - ไม่เกินร้อยละ 30
   - 300 บาทแรกไม่ถูกหัก

---
- ข้อมูลยืนยันตัวตน
''';
    final b = parseMarkdown(md);
    expect(b.map((e) => e.kind), [
      MdKind.h1,
      MdKind.paragraph,
      MdKind.h2,
      MdKind.paragraph,
      MdKind.numbered,
      MdKind.numbered,
      MdKind.bullet,
      MdKind.bullet,
      MdKind.rule,
      MdKind.bullet,
    ]);
    // Clause lines stay on their own lines, unchanged.
    expect(
      b[3].text,
      '1.1 ผู้กู้ขอกู้เงิน **3,000 บาท**\n1.2 สัญญามีผลเมื่อโอนเงิน',
    );
    expect(b[4].marker, '1.');
    expect(b[6].level, 1);
    expect(b[9].level, 0);
  });

  test('inline bold and italic; snake_case and stray stars stay text', () {
    const base = TextStyle();
    String flat(List<InlineSpan> spans) =>
        spans.map((s) => s.toPlainText()).join();
    final spans = parseInline('ก **ข** _ค_ loan_agreement 2*3', base);
    expect(flat(spans), 'ก ข ค loan_agreement 2*3');
    final bold = spans[1] as TextSpan;
    expect(bold.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('renders every word of the body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoanMarkdown('# หัวข้อ\n\nข้อความ **สำคัญ**\n- รายการ'),
        ),
      ),
    );
    expect(find.text('หัวข้อ'), findsOneWidget);
    expect(find.textContaining('สำคัญ', findRichText: true), findsOneWidget);
    expect(find.text('รายการ'), findsOneWidget);
  });
}

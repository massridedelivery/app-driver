import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_markdown.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Screen 18 (design 18C): the evidence card of what was accepted, then the
/// documents in full as expandable sections, then share / save. For a loan
/// ([loanId]) or an application ([applicationId]).
class LoanDocumentsScreen extends ConsumerWidget {
  const LoanDocumentsScreen({super.key, this.loanId, this.applicationId})
    : assert(loanId != null || applicationId != null);

  final String? loanId;
  final String? applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = loanId != null
        ? loanDocumentsProvider(loanId!)
        : applicationDocumentsProvider(applicationId!);
    final v = ref.watch(provider);
    return LoanPage(
      title: 'เอกสารสัญญาของฉัน',
      footer:
          v.hasValue && !v.hasError && v.requireValue.terms.documents.isNotEmpty
          ? Builder(
              builder: (c) => LoanPrimaryButton(
                'บันทึก / แชร์เอกสาร',
                onPressed: () => _share(c, v.requireValue),
              ),
            )
          : null,
      body: LoanAsync<AcceptedLoanDocuments>(
        value: v,
        errorTitle: 'โหลดเอกสารไม่สำเร็จ',
        onRetry: () => ref.invalidate(provider),
        builder: (docs) => _Body(docs: docs),
      ),
    );
  }

  Future<void> _share(BuildContext context, AcceptedLoanDocuments d) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'เอกสารสินเชื่อ ฉบับ ${d.terms.version}',
        text: loanDocumentsShareText(d),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

/// The driver's copy: the full bodies + version + sha256 + accepted_at,
/// and nothing else.
String loanDocumentsShareText(AcceptedLoanDocuments d) {
  final b = StringBuffer()
    ..writeln('ฉบับ: ${d.terms.version}')
    ..writeln('SHA-256: ${d.terms.sha256}');
  if (d.acceptedAt != null) {
    b.writeln('ยอมรับเมื่อ: ${formatBangkokDateTime(d.acceptedAt!)}');
  }
  for (final doc in d.terms.documents) {
    b
      ..writeln()
      ..writeln(doc.body.trim());
  }
  return b.toString();
}

/// `9f2c…e41a`.
String shortSha(String sha) => sha.length <= 10
    ? sha
    : '${sha.substring(0, 4)}…${sha.substring(sha.length - 4)}';

class _Body extends StatelessWidget {
  const _Body({required this.docs});

  final AcceptedLoanDocuments docs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = docs.terms;
    if (t.documents.isEmpty) {
      return LoanMessage(
        symbol: 'ⓘ',
        title: 'ยังไม่มีเอกสารสำหรับรายการนี้',
        body: 'หากต้องการสำเนา ติดต่อฝ่ายช่วยเหลือ',
        actionLabel: 'ติดต่อฝ่ายช่วยเหลือ',
        onAction: () => openLoanSupport(context),
      );
    }
    final pending = docs.status == LoanApplicationStatus.pending;
    final closedChip = switch (docs.status) {
      LoanApplicationStatus.rejected ||
      LoanApplicationStatus.cancelled ||
      LoanApplicationStatus.declined => applicationChip(docs.status),
      _ => null,
    };
    return LoanList(
      children: [
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'หลักฐานการยอมรับ',
                      style: AppTypography.caption3.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (closedChip != null) LoanChipView(closedChip),
                ],
              ),
              const SizedBox(height: 4),
              if (docs.acceptedAt != null)
                LoanFactRow('วันเวลา', formatBangkokDateTime(docs.acceptedAt!)),
              LoanFactRow('ฉบับ', t.version),
              GestureDetector(
                onLongPress: () => _copy(context, t.sha256),
                child: Row(
                  children: [
                    Expanded(
                      child: LoanFactRow(
                        'ลายนิ้วมือเอกสาร (SHA-256)',
                        shortSha(t.sha256),
                      ),
                    ),
                    IconButton(
                      tooltip: 'คัดลอก',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () => _copy(context, t.sha256),
                    ),
                  ],
                ),
              ),
              LoanFactRow('ยอดที่ขอกู้', bahtWords(docs.principal)),
              if (pending)
                const LoanFactRow('ยอดที่อนุมัติ', '◷ รอพิจารณา')
              else if (docs.approvedLower)
                LoanFactRow(
                  'ยอดที่อนุมัติ',
                  '${bahtWords(docs.approvedPrincipal!)} ⓘ',
                ),
              const SizedBox(height: 6),
              const LoanBullet('สัญญาและความเป็นส่วนตัว', symbol: '✓'),
              const LoanBullet('ยินยอมให้หักรายได้ (แยกต่างหาก)', symbol: '✓'),
            ],
          ),
        ),
        if (docs.approvedLower) ...[
          LoanBanner(
            symbol: 'ⓘ',
            title: 'เอกสารนี้แสดงยอดที่คุณขอกู้ ${bahtWords(docs.principal)}',
            lines: [
              'เจ้าหน้าที่อนุมัติ ${bahtWords(docs.approvedPrincipal!)} ยอดผ่อนจริงคิดจากยอดที่อนุมัติ',
            ],
            tone: LoanTone.neutral,
          ),
        ],
        if (docs.loanId != null)
          LoanLink(
            'ดูตัวเลขจริงของสินเชื่อ',
            onTap: () => context.push(LoanPaths.loan(docs.loanId!)),
          ),
        const SizedBox(height: 8),
        for (final d in t.documents)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: Text(
                d.separate ? '${d.title} (แยกต่างหาก)' : d.title,
                style: AppTypography.caption3.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [LoanMarkdown(d.body, color: p.textPrimary)],
            ),
          ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String sha) async {
    await Clipboard.setData(ClipboardData(text: sha));
    if (context.mounted) showLoanSnack(context, 'คัดลอกลายนิ้วมือเอกสารแล้ว');
  }
}

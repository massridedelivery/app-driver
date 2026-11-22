import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

/// Screen 2 (design 2A): the explainer page — amount hero, three steps, a
/// real sample cost, the driver's rights. Not eligible: the reason in Thai,
/// what to do, and a neutral explanation of the product.
class LoanOfferScreen extends ConsumerWidget {
  const LoanOfferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(loanOfferProvider);
    final eligible = offer.asData?.value.eligible == true;
    return LoanPage(
      title: 'สินเชื่อคนขับ',
      footer: !offer.hasValue
          ? null
          : eligible
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoanPrimaryButton(
                  'เริ่มขอสินเชื่อ',
                  onPressed: () => context.push(LoanPaths.apply),
                ),
                const SizedBox(height: 10),
                LoanSecondaryButton(
                  'ไว้ภายหลัง',
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            )
          : LoanSecondaryButton(
              'กลับ',
              onPressed: () => Navigator.maybePop(context),
            ),
      body: LoanAsync<LoanOffer>(
        value: offer,
        onRetry: () => ref.invalidate(loanOfferProvider),
        builder: (o) => LoanList(
          onRefresh: () => ref.refresh(loanOfferProvider.future),
          children: o.eligible
              ? _eligible(context, o)
              : _ineligible(context, ref, o),
        ),
      ),
    );
  }

  List<Widget> _eligible(BuildContext context, LoanOffer o) {
    final p = context.palette;
    final s = o.sampleDisclosure;
    return [
      Text(
        'กู้ได้สูงสุด',
        style: AppTypography.caption4.copyWith(color: p.textSecondary),
      ),
      Text(
        bahtShort(o.maxPrincipal),
        style: AppTypography.heading2.copyWith(color: p.textPrimary),
      ),
      Text(
        'ตั้งแต่ ${bahtWords(o.minPrincipal)} · ผ่อน ${o.minTermDays}–${o.maxTermDays} วัน',
        style: AppTypography.caption4.copyWith(color: p.textSecondary),
      ),
      const LoanSectionTitle('ทำงานอย่างไร'),
      ..._steps(context),
      if (s != null) ...[
        LoanSectionTitle(
          'ตัวอย่างค่าใช้จ่าย: กู้ ${bahtWords(s.principal)} ${s.termDays} วัน',
        ),
        LoanCostCard(
          dailyInstalment: s.dailyInstalment,
          termDays: s.termDays,
          annualRateBps: s.annualRateBps,
          totalFees: s.totalFees,
          maxTotalInterest: s.maxTotalInterest,
          maxTotalRepayment: s.maxTotalRepayment,
        ),
        const LoanSectionTitle('สิทธิ์ของคุณ'),
        ...loanRights(s),
      ],
    ];
  }

  List<Widget> _steps(BuildContext context) {
    final p = context.palette;
    Widget step(String n, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: loanGreen.withValues(alpha: 0.15),
            child: Text(
              n,
              style: AppTypography.caption5.copyWith(
                color: loanGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption3.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  body,
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return [
      step('1', 'ยื่นคำขอ', 'เลือกยอดและจำนวนวัน อ่านเอกสาร'),
      step('2', 'เจ้าหน้าที่พิจารณา', 'เงินจะเข้ากระเป๋าหลังอนุมัติเท่านั้น'),
      step('3', 'ผ่อนรายวันจากรายได้', 'เริ่มหักวันถัดจากวันที่ได้รับเงิน'),
    ];
  }

  List<Widget> _ineligible(BuildContext context, WidgetRef ref, LoanOffer o) {
    final p = context.palette;
    final rules = ref.watch(loanEligibilityProvider).asData?.value.rules;
    return [
      LoanDeclineBlock(copy: loanDeclineCopy(o.declineReason, rules: rules)),
      const LoanSectionTitle('สินเชื่อคนขับคืออะไร'),
      ..._steps(context),
      if (o.annualRateBps > 0)
        Text(
          'ดอกเบี้ย ${percentFromBps(o.annualRateBps)} ต่อปี · ไม่มีค่าธรรมเนียม',
          style: AppTypography.caption4.copyWith(color: p.textSecondary),
        ),
    ];
  }
}

/// RightsList, with the figures from a cost statement.
List<Widget> loanRights(LoanDisclosure s) => [
  const LoanBullet('ปิดยอดก่อนกำหนดได้ ไม่มีค่าปรับ', symbol: '✓'),
  LoanBullet(coolingOffLine(s.coolingOffDays), symbol: '✓'),
  if (s.keepFloorThb > 0)
    LoanBullet(
      'รายได้ ${bahtWords(s.keepFloorThb)}แรกของวัน ไม่ถูกหัก',
      symbol: '✓',
    ),
  if (s.deductionRateBps > 0)
    LoanBullet(
      'หักไม่เกิน ${percentFromBps(s.deductionRateBps)} ของรายได้ต่อวัน',
      symbol: '✓',
    ),
  const LoanBullet(
    'ยกเลิกการหักอัตโนมัติได้ทุกเมื่อ (หนี้ยังคงอยู่ ชำระเองได้)',
    symbol: '✓',
  ),
];

/// "คุณสมบัติการขอสินเชื่อ": the admin's text, as plain text.
class LoanEligibilityScreen extends ConsumerWidget {
  const LoanEligibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(loanEligibilityProvider);
    return LoanPage(
      title: 'คุณสมบัติการขอสินเชื่อ',
      body: LoanAsync<LoanEligibility>(
        value: v,
        onRetry: () => ref.invalidate(loanEligibilityProvider),
        builder: (e) => LoanList(
          children: [
            SelectableText(
              e.text,
              style: AppTypography.caption3.copyWith(
                color: context.palette.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

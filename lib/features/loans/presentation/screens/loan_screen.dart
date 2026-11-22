import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

/// One loan. [catchUp] false: Loan home (11A), or Paid off (16A) once
/// closed, or the written-off card (17A V3). [catchUp] true: the behind /
/// past due / written off card (17A).
class LoanScreen extends ConsumerStatefulWidget {
  const LoanScreen({super.key, required this.id, this.catchUp = false});

  final String id;
  final bool catchUp;

  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen> {
  DateTime _loadedAt = DateTime.now();

  Future<void> _refresh() async {
    ref.invalidate(loanDetailProvider(widget.id));
    await ref.read(loanDetailProvider(widget.id).future);
    _loadedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(loanDetailProvider(widget.id));
    ref.listen(loanDetailProvider(widget.id), (_, next) {
      if (next.hasValue && !next.isLoading) _loadedAt = DateTime.now();
    });
    final l = v.asData?.value.loan;
    final today = bangkokDay(DateTime.now());
    final String title;
    if (l == null) {
      title = 'สินเชื่อของฉัน';
    } else if (widget.catchUp) {
      title = 'สินเชื่อ ${bahtWords(l.principal)}';
    } else {
      title = 'สินเชื่อของฉัน';
    }
    return LoanPage(
      title: title,
      trailing: l == null || l.status == LoanStatus.paidOff
          ? null
          : LoanChipView(loanChip(l, today)),
      body: LoanAsync<LoanDetail>(
        value: v,
        onRetry: () => ref.invalidate(loanDetailProvider(widget.id)),
        builder: (detail) {
          final loan = detail.loan;
          if (loan.status == LoanStatus.paidOff) {
            return _PaidOffBody(detail: detail, onRefresh: _refresh);
          }
          if (widget.catchUp || loan.status == LoanStatus.writtenOff) {
            return _CatchUpBody(detail: detail, onRefresh: _refresh);
          }
          return _HomeBody(
            detail: detail,
            loadedAt: _loadedAt,
            onRefresh: _refresh,
          );
        },
      ),
    );
  }
}

// ── 11A Loan home ──────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.detail,
    required this.loadedAt,
    required this.onRefresh,
  });

  final LoanDetail detail;
  final DateTime loadedAt;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = detail.loan;
    final today = bangkokDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final paused = l.isPausedOn(today);
    final progress = l.scheduledTotal <= 0
        ? 0.0
        : (l.paidTotal / l.scheduledTotal).clamp(0.0, 1.0);
    final yEvents = detail.eventsOn(yesterday);
    final yDeducted = _sum(yEvents, LoanEventType.deduction);
    final yShort = _sum(yEvents, LoanEventType.shortfall);
    return LoanList(
      onRefresh: onRefresh,
      children: [
        Text(
          'ยอดคงเหลือ',
          style: AppTypography.caption4.copyWith(color: p.textSecondary),
        ),
        Text(
          baht2(l.balance),
          style: AppTypography.heading2.copyWith(color: p.textPrimary),
        ),
        Text(
          'เงินต้น ${baht2(l.outstandingPrincipal)} · ดอกเบี้ย ${baht2(l.accruedInterest)}',
          style: AppTypography.caption4.copyWith(color: p.textSecondary),
        ),
        Text(
          'อัปเดต ${formatBangkokTime(loadedAt)}',
          style: AppTypography.caption5.copyWith(color: p.textTertiary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: loanGreen,
                backgroundColor: p.border,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).floor()}%',
              style: AppTypography.caption5.copyWith(color: p.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'จ่ายแล้ว ${baht2(l.paidTotal)} จาก ${baht2(l.scheduledTotal)}',
          style: AppTypography.caption4.copyWith(color: p.textPrimary),
        ),
        if (l.maturesOn != null)
          Text(
            'ครบกำหนด ${formatDay(l.maturesOn!)}',
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
        const SizedBox(height: 8),
        if (l.status == LoanStatus.delinquent)
          LoanBanner(
            symbol: '!',
            title:
                'เลยกำหนด${l.maturesOn == null ? '' : ' ${formatDay(l.maturesOn!)}'} แล้ว',
            lines: ['ยังเหลือ ${baht2(l.balance)} · ยังชำระได้ตามปกติ'],
            tone: LoanTone.warning,
            actions: [
              TextButton(
                onPressed: () => context.push(LoanPaths.catchUp(l.id)),
                child: const Text('ดูวิธีชำระที่เหลือ'),
              ),
            ],
          )
        else if (l.daysBehind > 0)
          LoanBanner(
            symbol: '!',
            title: 'ค้าง ${l.daysBehind} วัน · ยอดค้าง ${baht2(l.arrears)}',
            lines: [
              if (l.dueToday > 0) 'วันนี้หักได้สูงสุด ${baht2(l.dueToday)}',
            ],
            tone: LoanTone.warning,
            actions: [
              TextButton(
                onPressed: () => context.push(LoanPaths.pay(l.id)),
                child: const Text('จ่ายยอดค้างตอนนี้'),
              ),
              TextButton(
                onPressed: () => context.push(LoanPaths.catchUp(l.id)),
                child: const Text('ทำไมถึงค้าง'),
              ),
            ],
          ),
        if (l.interestFreePayoff && l.coolingOffUntil != null)
          LoanBanner(
            symbol: '★',
            title: coolingOffLine(l.disclosure.coolingOffDays),
            lines: [
              'ปิดยอด ${baht2(l.payoffAmount)} ${coolingOffUntilText(l.coolingOffUntil!)}',
            ],
            tone: LoanTone.success,
            actions: [
              TextButton(
                onPressed: () => context.push(LoanPaths.pay(l.id)),
                child: const Text('ปิดยอด'),
              ),
            ],
          ),
        Divider(height: 24, color: p.border),
        _dayRow(
          context,
          'วันนี้',
          paused
              ? [
                  '‖ พักชำระ ไม่หักรายได้',
                  'เริ่มหักอีกครั้ง ${formatDay(l.pausedUntil!.add(const Duration(days: 1)))}',
                ]
              : l.consentRevoked
              ? ['ค่างวด ${baht2(l.dailyInstalment)} · ชำระเอง']
              : l.scheduleStart != null && today.isBefore(l.scheduleStart!)
              ? ['เริ่มหักวันที่ ${formatDay(l.scheduleStart!)}']
              : l.dueToday <= 0
              ? ['วันนี้ไม่มียอดต้องหัก']
              : [
                  'ยอดหักวันนี้ ${baht2(l.dueToday)}',
                  'หักจากรายได้วันนี้ คืนนี้',
                ],
        ),
        if (yEvents.isNotEmpty)
          InkWell(
            onTap: () =>
                context.push(LoanPaths.notice(l.id, dayKey(yesterday))),
            child: _dayRow(context, 'เมื่อวาน', [
              yShort > 0
                  ? '◐ หักได้ ${baht2(yDeducted)} · ขาด ${baht2(yShort)}'
                  : '✓ หักแล้ว ${baht2(yDeducted)}',
            ], chevron: true),
          ),
        Divider(height: 24, color: p.border),
        _AutoDeductionRow(loan: l),
        Divider(height: 24, color: p.border),
        LoanPrimaryButton(
          'จ่ายเงิน / ปิดยอด',
          onPressed: () => context.push(LoanPaths.pay(l.id)),
        ),
        const SizedBox(height: 6),
        LoanLink(
          'ประวัติการชำระ',
          onTap: () => context.push(LoanPaths.history(l.id)),
        ),
        LoanLink(
          'เอกสารของฉัน',
          onTap: () => context.push(LoanPaths.documents(l.id)),
        ),
        const SizedBox(height: 8),
        Text(
          'จ่ายก่อนกำหนดได้ ไม่มีค่าปรับ',
          style: AppTypography.caption5.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }

  Widget _dayRow(
    BuildContext context,
    String label,
    List<String> lines, {
    bool chevron = false,
  }) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTypography.caption3.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in lines)
                  Text(
                    s,
                    style: AppTypography.caption4.copyWith(
                      color: p.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          if (chevron) Icon(Icons.chevron_right, color: p.textSecondary),
        ],
      ),
    );
  }
}

double _sum(List<LoanEvent> events, String type) {
  var t = 0.0;
  for (final e in events) {
    if (e.type == type) t += e.amount;
  }
  return (t * 100).round() / 100;
}

/// 15D: the switch never flips on a tap; it opens two sheets.
class _AutoDeductionRow extends ConsumerStatefulWidget {
  const _AutoDeductionRow({required this.loan});

  final Loan loan;

  @override
  ConsumerState<_AutoDeductionRow> createState() => _AutoDeductionRowState();
}

class _AutoDeductionRowState extends ConsumerState<_AutoDeductionRow> {
  bool _sending = false;

  Future<bool?> _sheet({
    required String title,
    required List<String> lines,
    required String go,
  }) => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (s) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.heading5.copyWith(
                color: s.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l,
                  style: AppTypography.caption4.copyWith(
                    color: s.palette.textPrimary,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            LoanFooterButtons(
              secondary: 'ไม่ปิด',
              onSecondary: () => Navigator.of(s).pop(false),
              primary: go,
              onPrimary: () => Navigator.of(s).pop(true),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _revoke() async {
    final l = widget.loan;
    final first = await _sheet(
      title: 'ปิดการหักอัตโนมัติ?',
      lines: [
        'ยอดหนี้ ${baht2(l.balance)} ยังอยู่ และคุณต้องจ่ายเอง',
        'วันละ ${baht2(l.dailyInstalment)}${l.maturesOn == null ? '' : ' ภายใน ${formatDay(l.maturesOn!)}'}',
        'เปิดกลับต้องติดต่อฝ่ายช่วยเหลือ',
      ],
      go: 'ต่อไป',
    );
    if (first != true || !mounted) return;
    final second = await _sheet(
      title: 'ยืนยันปิดการหักอัตโนมัติ',
      lines: const [
        'หลังปิด ระบบจะไม่หักจากรายได้อีก ยอดหนี้ยังอยู่ ชำระเองได้ที่ "จ่ายเงิน"',
      ],
      go: 'ยืนยันปิด',
    );
    if (second != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await ref.read(loanApiProvider).revokeConsent(l.id);
      LoanUpdates.instance.notifyChanged();
      if (mounted) showLoanSnack(context, 'ปิดการหักอัตโนมัติแล้ว');
    } on LoanApiException catch (e) {
      if (!mounted) return;
      if (e.lendingOff) {
        leaveLoans(context);
      } else if (e.code == 'CONSENT_CONFLICT') {
        LoanUpdates.instance.notifyChanged();
      } else {
        showLoanSnack(
          context,
          'ยังปิดการหักอัตโนมัติไม่สำเร็จ กรุณาลองอีกครั้ง · ตอนนี้การหักอัตโนมัติยังเปิดอยู่',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = widget.loan;
    final text = AppTypography.caption4.copyWith(color: p.textPrimary);
    if (l.consentRevoked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⦸ หักอัตโนมัติ: ปิด (ตั้งแต่ ${formatBangkokDateTime(l.consentRevokedAt!)})',
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text('ยอดหนี้ยังอยู่ ชำระเองที่ "จ่ายเงิน"', style: text),
          Text('หากไม่ได้จ่าย ยอดจะค้างและเลยกำหนดได้', style: text),
          const SizedBox(height: 4),
          Text('ต้องการเปิดหักอัตโนมัติอีกครั้ง?', style: text),
          LoanLink(
            'ติดต่อฝ่ายช่วยเหลือ',
            onTap: () => openLoanSupport(context),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '⚙ หักอัตโนมัติ',
                style: AppTypography.caption3.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_sending)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Semantics(
                label: 'หักอัตโนมัติ เปิดอยู่ แตะเพื่อดูวิธีปิด',
                child: Switch(
                  value: true,
                  activeThumbColor: loanGreen,
                  onChanged: (_) => _revoke(),
                ),
              ),
            const SizedBox(width: 4),
            Text('เปิด', style: text),
          ],
        ),
        if (l.keepFloorThb > 0)
          Text('เว้นรายได้ ${bahtWords(l.keepFloorThb)}แรกทุกวัน', style: text),
        if (l.deductionRateBps > 0)
          Text(
            'หักไม่เกิน ${percentFromBps(l.deductionRateBps)} ของรายได้ต่อวัน',
            style: text,
          ),
      ],
    );
  }
}

// ── 17A Behind / past due / written off ───────────────────────────────

class _CatchUpBody extends StatelessWidget {
  const _CatchUpBody({required this.detail, required this.onRefresh});

  final LoanDetail detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = detail.loan;
    final today = bangkokDay(DateTime.now());
    final body = AppTypography.caption4.copyWith(color: p.textPrimary);

    if (l.status == LoanStatus.writtenOff) {
      final w = detail.writeOff;
      return LoanList(
        onRefresh: onRefresh,
        children: [
          Text(
            'สินเชื่อนี้ถูกตัดเป็นหนี้สูญแล้ว',
            style: AppTypography.heading5.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 10),
          LoanCard(
            child: Column(
              children: [
                if (w != null) ...[
                  LoanFactRow('ยอด ณ วันที่ตัดหนี้สูญ', baht2(w.amount)),
                  if (w.day != null) LoanFactRow('วันที่', formatDay(w.day!)),
                ],
                LoanFactRow('ยอดคงเหลือ', baht2(l.payoffAmount), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ยอดคงเหลือยังชำระได้ตามปกติ เมื่อชำระครบ สินเชื่อจะปิดยอด',
            style: body,
          ),
          const SizedBox(height: 4),
          Text('หากต้องการชำระหรือสอบถาม ติดต่อฝ่ายช่วยเหลือ', style: body),
          const SizedBox(height: 16),
          LoanPrimaryButton(
            'ชำระยอดคงเหลือ',
            onPressed: () => context.push(LoanPaths.pay(l.id)),
          ),
          const SizedBox(height: 10),
          LoanSecondaryButton(
            'ติดต่อฝ่ายช่วยเหลือ',
            onPressed: () => openLoanSupport(context),
          ),
          LoanLink(
            'ดูประวัติ',
            onTap: () => context.push(LoanPaths.history(l.id)),
          ),
          LoanLink(
            'เอกสารสัญญาของฉัน',
            onTap: () => context.push(LoanPaths.documents(l.id)),
          ),
        ],
      );
    }

    if (!l.isBehind) {
      return LoanMessage(
        symbol: '✓',
        title: 'ตามทันแล้ว',
        body: 'ไม่มียอดค้าง',
        actionLabel: 'ไปหน้าสินเชื่อ',
        onAction: () => context.pushReplacement(LoanPaths.loan(l.id)),
      );
    }

    final pastDue = l.status == LoanStatus.delinquent;
    final paused = l.isPausedOn(today);
    final shortfall = detail.lastShortfall;
    final overdueDays = pastDue && l.maturesOn != null
        ? today.difference(l.maturesOn!).inDays
        : 0;
    final payLabel = pastDue
        ? 'ชำระยอดค้าง'
        : 'ชำระยอดค้าง ${baht2(l.arrears)}';
    final payButton = paused
        ? LoanSecondaryButton(
            payLabel,
            onPressed: () => context.push(LoanPaths.pay(l.id)),
          )
        : LoanPrimaryButton(
            payLabel,
            onPressed: () => context.push(LoanPaths.pay(l.id)),
          );
    return LoanList(
      onRefresh: onRefresh,
      children: [
        Text(
          pastDue
              ? 'สินเชื่อเลยกำหนดชำระแล้ว'
              : 'ยอดผ่อนค้างอยู่ ${l.daysBehind} วัน',
          style: AppTypography.heading5.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          pastDue
              ? 'ยังชำระได้ตามปกติ ทุกบาทที่จ่ายช่วยลดยอดค้าง'
              : 'เกิดขึ้นได้ ไม่ต้องกังวล เราช่วยคุณตามยอดให้ทันได้',
          style: body,
        ),
        const SizedBox(height: 12),
        LoanCard(
          child: Column(
            children: [
              LoanFactRow(
                pastDue ? 'ยอดที่ต้องชำระ' : 'ยอดค้าง',
                baht2(pastDue ? l.balance : l.arrears),
                bold: true,
              ),
              LoanFactRow('ผ่อนวันละ', baht2(l.dailyInstalment)),
              LoanFactRow('ยอดคงเหลือทั้งหมด', baht2(l.balance)),
              if (l.maturesOn != null)
                LoanFactRow(
                  'ครบกำหนด',
                  overdueDays > 0
                      ? '${formatDay(l.maturesOn!)} (เลยมาแล้ว $overdueDays วัน)'
                      : formatDay(l.maturesOn!),
                ),
            ],
          ),
        ),
        if (shortfall != null) ...[
          const LoanSectionTitle('ทำไมถึงค้าง'),
          LoanBullet(
            loanShortfallExplain(
              shortfall.note,
              keepFloor: l.keepFloorThb,
              deductionRateBps: l.deductionRateBps,
            ),
            symbol: 'ⓘ',
          ),
        ],
        const SizedBox(height: 10),
        if (paused)
          Text(
            'พักชำระถึง ${formatDay(l.pausedUntil!)} ระหว่างนี้จะไม่หักจากรายได้',
            style: body,
          )
        else if (l.consentRevoked)
          Text(
            'การหักอัตโนมัติปิดอยู่ กรุณาชำระเองผ่าน "$payLabel"',
            style: body,
          )
        else
          Text(
            'การหักจากรายได้ยังทำงานตามปกติ${l.dueToday > 0 ? ' วันนี้หักได้สูงสุด ${baht2(l.dueToday)}' : ''}'
            '${l.keepFloorThb > 0 ? ' โดยยังเว้น ${bahtWords(l.keepFloorThb)}แรกไว้ให้คุณเสมอ' : ''}',
            style: body,
          ),
        const SizedBox(height: 16),
        payButton,
        const SizedBox(height: 10),
        LoanSecondaryButton(
          'ชำระจำนวนอื่น',
          onPressed: () => context.push(LoanPaths.pay(l.id)),
        ),
        const SizedBox(height: 12),
        Text(
          'มีปัญหาเรื่องรายได้? คุยกับเราได้ เจ้าหน้าที่อาจช่วยพักชำระหรือขยายระยะผ่อนให้',
          style: body,
        ),
        LoanLink('ติดต่อฝ่ายช่วยเหลือ', onTap: () => openLoanSupport(context)),
      ],
    );
  }
}

// ── 16A Paid off ───────────────────────────────────────────────────────

class _PaidOffBody extends ConsumerWidget {
  const _PaidOffBody({required this.detail, required this.onRefresh});

  final LoanDetail detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = detail.loan;
    final offer = ref.watch(loanOfferProvider).asData?.value;
    final paidDay = l.paidOffAt == null ? null : bangkokDay(l.paidOffAt!);
    final early = paidDay != null && l.maturesOn != null
        ? l.maturesOn!.difference(paidDay).inDays
        : 0;
    final inCoolingOff =
        l.interestPaid == 0 &&
        l.paidOffAt != null &&
        l.coolingOffUntil != null &&
        l.paidOffAt!.isBefore(l.coolingOffUntil!);
    final body = AppTypography.caption4.copyWith(color: p.textPrimary);
    String? stepUp;
    String? stepUpLink;
    if (offer != null) {
      if (offer.eligible && offer.maxPrincipal > l.principal) {
        stepUp =
            'วงเงินครั้งต่อไปของคุณสูงขึ้นเป็น ${bahtWords(offer.maxPrincipal)}';
        stepUpLink = 'ดูรายละเอียดสินเชื่อ';
      } else if (offer.eligible) {
        stepUp = 'หากต้องการกู้อีกครั้ง ตรวจสอบสิทธิ์ได้ที่หน้าสินเชื่อ';
        stepUpLink = 'ดูสิทธิ์ของฉัน';
      } else {
        stepUpLink = 'ดูสิทธิ์ของฉัน';
      }
    }
    return LoanList(
      onRefresh: onRefresh,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text(
            '★',
            style: TextStyle(
              fontSize: 30,
              color: loanGreen.withValues(alpha: 0.9),
            ),
          ),
        ),
        Center(
          child: Text(
            'ปิดยอดแล้ว',
            style: AppTypography.heading4.copyWith(color: p.textPrimary),
          ),
        ),
        if (l.paidOffAt != null)
          Center(
            child: Text(
              'ชำระครบเมื่อ ${formatBangkokDateTime(l.paidOffAt!)}',
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
          ),
        if (early > 0)
          Center(
            child: Text(
              'ปิดก่อนกำหนด $early วัน',
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
          ),
        const SizedBox(height: 14),
        LoanCard(
          child: Column(
            children: [
              LoanFactRow('เงินต้นที่ชำระ', baht2(l.principalPaid)),
              LoanFactRow('ดอกเบี้ยที่ชำระ', baht2(l.interestPaid)),
              LoanFactRow('ค่าธรรมเนียม', baht2(l.disclosure.totalFees)),
              Divider(color: p.border),
              LoanFactRow('รวมที่ชำระทั้งหมด', baht2(l.paidTotal), bold: true),
            ],
          ),
        ),
        if (inCoolingOff) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: LoanChipView(
              LoanChip('✓', 'ปิดภายใน 7 วัน ไม่เสียดอกเบี้ย', LoanTone.success),
            ),
          ),
        ],
        const SizedBox(height: 10),
        const LoanBullet('ไม่มียอดค้าง', symbol: '✓'),
        const LoanBullet('หยุดหักจากรายได้แล้ว', symbol: '✓'),
        const SizedBox(height: 6),
        LoanLink(
          'ดูประวัติการชำระ',
          onTap: () => context.push(LoanPaths.history(l.id)),
        ),
        LoanLink(
          'เอกสารสัญญาของฉัน',
          onTap: () => context.push(LoanPaths.documents(l.id)),
        ),
        const SizedBox(height: 12),
        LoanPrimaryButton(
          'กลับหน้าหลัก',
          onPressed: () => context.go(AppRoutes.homeNamedPage),
        ),
        if (stepUp != null) ...[
          const SizedBox(height: 14),
          Text(stepUp, style: body),
        ],
        if (stepUpLink != null)
          LoanLink(stepUpLink, onTap: () => context.push(LoanPaths.offer)),
      ],
    );
  }
}

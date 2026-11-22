import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_notice.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

/// Screen 14 (design 14B): what the 08:00 `loan_daily_notice` opens — a
/// slip for [day]'s deduction: asked, taken, short and why, the split, the
/// balance and arrears now.
class LoanNoticeScreen extends ConsumerWidget {
  const LoanNoticeScreen({super.key, required this.id, required this.day});

  final String id;

  /// `YYYY-MM-DD` (Bangkok).
  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(loanDetailProvider(id));
    final date = parseApiDay(day);
    return LoanPage(
      title: date == null ? 'ใบสรุปการหักรายได้' : formatDay(date),
      body: LoanAsync<LoanDetail>(
        value: v,
        errorTitle: 'โหลดข้อมูลไม่สำเร็จ',
        onRetry: () => ref.invalidate(loanDetailProvider(id)),
        builder: (d) {
          final l = d.loan;
          if (l.status == LoanStatus.paidOff ||
              l.status == LoanStatus.writtenOff ||
              date == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.pushReplacement(
                l.status == LoanStatus.writtenOff
                    ? LoanPaths.catchUp(l.id)
                    : LoanPaths.loan(l.id),
              );
            });
            return const SizedBox.shrink();
          }
          return _Slip(
            detail: d,
            day: date,
            onRefresh: () => ref.refresh(loanDetailProvider(id).future),
          );
        },
      ),
    );
  }
}

class _Slip extends StatelessWidget {
  const _Slip({
    required this.detail,
    required this.day,
    required this.onRefresh,
  });

  final LoanDetail detail;
  final DateTime day;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = detail.loan;
    final n = loanNoticeFor(detail, day);
    final body = AppTypography.caption4.copyWith(color: p.textPrimary);
    Widget dots() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '· · · · · · · · · · · · · · · · · · · ·',
        style: TextStyle(color: p.textTertiary),
      ),
    );
    final goLoan = LoanPrimaryButton(
      'ดูสินเชื่อ',
      onPressed: () => context.pushReplacement(LoanPaths.loan(l.id)),
    );

    if (n.kind == LoanNoticeKind.noData) {
      return LoanMessage(
        symbol: 'ⓘ',
        title: 'ยังไม่มีข้อมูลการหักของวันที่ ${formatDay(day)}',
        body: 'ระบบอาจกำลังประมวลผล ลองใหม่อีกครั้งภายหลัง',
        secondaryLabel: 'ไปหน้าสินเชื่อ',
        onSecondary: () => context.pushReplacement(LoanPaths.loan(l.id)),
      );
    }
    if (n.kind == LoanNoticeKind.paused || n.kind == LoanNoticeKind.autoOff) {
      return LoanList(
        onRefresh: onRefresh,
        children: [
          Text(
            n.kind == LoanNoticeKind.paused
                ? '‖ วันนั้นพักชำระ ไม่มีการหัก${l.pausedUntil == null ? '' : ' · เริ่มหักอีกครั้ง ${formatDay(l.pausedUntil!.add(const Duration(days: 1)))}'}'
                : '⦸ ไม่มีการหักอัตโนมัติ · ค่างวด ${baht2(l.dailyInstalment)} จ่ายเองได้ที่ปุ่มด้านล่าง',
            style: AppTypography.caption2.copyWith(color: p.textPrimary),
          ),
          if (l.arrears > 0) ...[
            const SizedBox(height: 10),
            LoanFactRow('ค้างรวม', baht2(l.arrears), bold: true),
            if (l.daysBehind > 0) Text('ค้าง ${l.daysBehind} วัน', style: body),
          ],
          const SizedBox(height: 20),
          if (l.arrears > 0 || n.kind == LoanNoticeKind.autoOff) ...[
            LoanSecondaryButton(
              'จ่ายเงิน',
              onPressed: () => context.push(LoanPaths.pay(l.id)),
            ),
            const SizedBox(height: 10),
          ],
          goLoan,
        ],
      );
    }

    return LoanList(
      onRefresh: onRefresh,
      children: [
        Text(
          'ใบสรุปการหักรายได้',
          style: AppTypography.heading5.copyWith(color: p.textPrimary),
        ),
        dots(),
        LoanFactRow('ยอดที่ต้องหัก', baht2(n.asked)),
        LoanFactRow('หักจากรายได้', '−${baht2(n.deducted)}'),
        LoanFactRow(
          'ยังขาด',
          n.shortfall > 0 ? baht2(n.shortfall) : '${baht2(0)} ✓',
          bold: true,
        ),
        if (n.shortfall > 0)
          Text(
            'เหตุผล: ${loanShortfallLabel(n.reason)} — ${loanShortfallExplain(n.reason, keepFloor: l.keepFloorThb, deductionRateBps: l.deductionRateBps)}',
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
        dots(),
        if (n.deducted > 0) ...[
          LoanFactRow('ดอกเบี้ยที่ตัด', baht2(n.interest)),
          LoanFactRow('เงินต้นที่ตัด', baht2(n.principal)),
        ],
        LoanFactRow('ยอดคงเหลือตอนนี้', baht2(l.balance)),
        LoanFactRow('ค้างรวม', baht2(l.arrears)),
        if (l.daysBehind > 0) Text('ค้าง ${l.daysBehind} วัน', style: body),
        dots(),
        if (n.shortfall > 0 || l.arrears > 0)
          Text(
            'ส่วนที่ขาดจะหักเพิ่มในวันถัดไป (วันละไม่เกิน 2 งวด'
            '${l.deductionRateBps > 0 ? ' และไม่เกิน ${percentFromBps(l.deductionRateBps)} ของรายได้' : ''}'
            '${l.keepFloorThb > 0 ? ' · เว้น ${bahtWords(l.keepFloorThb)}แรกเสมอ' : ''})',
            style: body,
          )
        else
          Text('หักครบแล้ว ขอบคุณ', style: body),
        const SizedBox(height: 20),
        if (l.arrears > 0) ...[
          LoanSecondaryButton(
            'จ่ายส่วนที่ขาด',
            onPressed: () => context.push(LoanPaths.pay(l.id)),
          ),
          const SizedBox(height: 10),
        ],
        goLoan,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_history.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

/// Screen 12 (design 12A): every movement, grouped by Bangkok day, newest
/// day first; split and reason under each amount.
class LoanHistoryScreen extends ConsumerWidget {
  const LoanHistoryScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(loanDetailProvider(id));
    return LoanPage(
      title: 'ประวัติการชำระ',
      body: LoanAsync<LoanDetail>(
        value: v,
        errorTitle: 'โหลดประวัติไม่สำเร็จ',
        skeletonLines: 6,
        onRetry: () => ref.invalidate(loanDetailProvider(id)),
        builder: (detail) {
          final p = context.palette;
          final groups = groupEventsByDay(detail.events);
          final onlyDisbursement = detail.events.every(
            (e) => e.type == LoanEventType.disbursement,
          );
          final start = detail.loan.scheduleStart;
          return LoanList(
            onRefresh: () => ref.refresh(loanDetailProvider(id).future),
            children: [
              if (onlyDisbursement && start != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'งวดแรกจะหักจากรายได้วันที่ ${formatDay(start)}',
                    style: AppTypography.caption4.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
              for (final g in groups) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: p.border, width: 2)),
                  ),
                  child: Text(
                    g.day == null ? 'ไม่ระบุวัน' : formatDay(g.day!),
                    style: AppTypography.caption4.copyWith(
                      color: p.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final e in g.events)
                  _EventRow(event: e, loan: detail.loan),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.loan});

  final LoanEvent event;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final e = event;
    final view = eventView(e);
    final sub = <String>[
      if (e.type == LoanEventType.shortfall) loanShortfallLabel(e.note),
      if (e.type != LoanEventType.shortfall &&
          e.note != null &&
          showsEventNote(e.type))
        e.note!,
      if (e.principalComponent > 0 || e.interestComponent > 0)
        'เงินต้น ${baht2(e.principalComponent)} · ดอกเบี้ย ${baht2(e.interestComponent)}',
    ];
    return InkWell(
      onTap: e.type == LoanEventType.shortfall
          ? () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: p.sheet,
              builder: (s) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    loanShortfallExplain(
                      e.note,
                      keepFloor: loan.keepFloorThb,
                      deductionRateBps: loan.deductionRateBps,
                    ),
                    style: AppTypography.caption3.copyWith(
                      color: s.palette.textPrimary,
                    ),
                  ),
                ),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                view.symbol,
                style: AppTypography.caption3.copyWith(color: p.textSecondary),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loanEventLabel(e.type),
                    style: AppTypography.caption3.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  for (final s in sub)
                    Text(
                      e.type == LoanEventType.shortfall && s == sub.first
                          ? '$s  ⓘ'
                          : s,
                      style: AppTypography.caption5.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (view.amount != null)
              Text(
                view.amount!,
                style: AppTypography.caption3.copyWith(
                  color: view.positive ? loanGreen : p.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

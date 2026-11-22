import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/domain/loan_entry.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

/// Whether the "สินเชื่อคนขับ" row takes a place in the profile's
/// "บริการอื่น" list. Hidden while lending is off (404), and while the very
/// first check is still running or failed before the app ever saw lending
/// on — so drivers on a server without lending never see the row flash.
bool loanEntryShown(AsyncValue<LoanEntry?> v) {
  // A refresh keeps the last answer on screen.
  if (v.hasValue) return v.value != null;
  return LoanAvailability.instance.value == true;
}

/// Design 1H: icon tile, title, one status line, chip, chevron.
class LoanEntryRow extends ConsumerWidget {
  const LoanEntryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(loanEntryProvider);
    final p = context.palette;
    final entry = v.asData?.value;
    final Widget second;
    if (entry != null) {
      second = Text(
        entry.line,
        style: AppTypography.caption5.copyWith(color: p.textSecondary),
      );
    } else if (v.isLoading) {
      second = Container(
        height: 12,
        width: 160,
        margin: const EdgeInsets.only(top: 3),
        decoration: BoxDecoration(
          color: p.border,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    } else {
      second = Text(
        'ดูสถานะสินเชื่อ',
        style: AppTypography.caption5.copyWith(color: p.textSecondary),
      );
    }

    return InkWell(
      onTap: () {
        if (entry != null) {
          context.push(entry.route);
        } else if (v.hasError) {
          ref.invalidate(loanEntryProvider);
        } else {
          context.push(LoanPaths.offer);
        }
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: loanGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: loanGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สินเชื่อคนขับ',
                      style: AppTypography.caption3.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    second,
                    if (entry?.chip != null) ...[
                      const SizedBox(height: 6),
                      LoanChipView(entry!.chip!),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/router/app_routes.dart';

/// Home card for the cash-job gate (BE dev115): red while cash jobs are
/// blocked, amber for a low-credit warning, hidden otherwise. The driver
/// stays online and keeps getting QR / card jobs either way.
class CashJobGateCard extends ConsumerWidget {
  const CashJobGateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(
      walletControllerProvider.select((s) => s.cashJobGate),
    );
    if (gate == null || !gate.hasNotice) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CashJobNotice(
        gate: gate,
        onTopUp: () => context.push(AppRoutes.creditWalletNamedPage),
      ),
    );
  }
}

/// Title, "รับได้เฉพาะงาน QR/บัตร · ยอด … · เกณฑ์ …", the admin message and a
/// "เติมเครดิต" button.
class CashJobNotice extends StatelessWidget {
  final CashJobGate gate;
  final VoidCallback onTopUp;

  const CashJobNotice({super.key, required this.gate, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    final accent = gate.cashBlocked
        ? AppColors.semanticErrorFgHigh
        : AppColors.foundationOrange500;
    final message = gate.message;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              gate.cashBlocked
                  ? Icons.money_off_csred_outlined
                  : Icons.account_balance_wallet_outlined,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gate.title,
                  style: AppTypography.label2.copyWith(color: accent),
                ),
                const SizedBox(height: 2),
                Text(
                  gate.statusLine,
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.caption5.copyWith(
                      color: context.palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTopUp,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foundationGreen700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'เติมเครดิต',
              style: AppTypography.caption4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when an accept came back 403 for the cash-job limit: same copy as
/// the home card, with "เติมเครดิต". The caller closes the offer.
Future<void> showCashJobBlockedDialog(BuildContext context, CashJobGate? gate) {
  // The summary may still say "ok" (balance just dropped): the 403 is the
  // truth, so fall back to the block copy.
  final shown = (gate != null && gate.cashBlocked)
      ? gate
      : CashJobGate(
          balance: gate?.balance ?? 0,
          canReceiveCashJobs: false,
          blockBalance: gate?.blockBalance,
        );
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.palette.surface,
      title: Text(
        shown.title,
        style: AppTypography.heading5.copyWith(
          color: AppColors.semanticErrorFgHigh,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shown.statusLine,
            style: AppTypography.caption4.copyWith(
              color: dialogContext.palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shown.message,
            style: AppTypography.caption4.copyWith(
              color: dialogContext.palette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // push so the credit wallet keeps a way back.
                  AppRouter.router.push(AppRoutes.creditWalletNamedPage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foundationGreen700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'เติมเครดิต',
                  style: AppTypography.label1.copyWith(color: Colors.white),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'รับทราบ',
                style: AppTypography.caption3.copyWith(
                  color: dialogContext.palette.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

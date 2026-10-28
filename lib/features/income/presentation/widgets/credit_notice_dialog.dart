import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

/// Shown when an accept came back 403 for the cash-job limit: the block
/// copy with "เติมเครดิต". The caller closes the offer.
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
  return showCreditNoticeDialog(context, shown);
}

/// The credit dialog on home (app open, back from a job, after going online)
/// whenever the gate has something to say: red for งานเงินสดถูกระงับ, amber
/// for เครดิตเหลือน้อย. "เติมเครดิต" opens the credit wallet.
Future<void> showCreditNoticeDialog(BuildContext context, CashJobGate shown) {
  final accent = shown.cashBlocked ? context.brand.bad : context.brand.wait;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.palette.surface,
      title: Text(
        shown.title,
        style: AppTypography.heading5.copyWith(color: accent),
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
          if (shown.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              shown.message,
              style: AppTypography.caption4.copyWith(
                color: dialogContext.palette.textSecondary,
                height: 1.5,
              ),
            ),
          ],
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
                  backgroundColor: dialogContext.brand.red,
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
